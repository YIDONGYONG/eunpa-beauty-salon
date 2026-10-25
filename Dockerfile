# 本番用イメージ（Rails + Litestream を1コンテナに）。ビルドは GitHub Actions で行い、VM では pull するだけ。
# 1GB メモリの VM では docker build / assets:precompile を実行しないこと（ADR 0004）。
#   ビルド: docker build -t eunpa .      開発用は Dockerfile.dev（docker compose が使用）
ARG RUBY_VERSION=3.4
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    LANG=C.UTF-8 \
    DATA_DIR=/data

# 実行に必要なものだけ: libvips（画像変換）/ libjemalloc2（メモリ断片化の抑制）/ sqlite3（保守用 CLI）/ curl（ヘルスチェック）
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists/*

# jemalloc を使う（Ruby のメモリ使用量が減る）
ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so

# ---- ビルド用ステージ（コンパイラはここだけ。最終イメージには入らない）----
FROM base AS build
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf ~/.bundle "${BUNDLE_PATH:-/usr/local/bundle}"/ruby/*/cache

COPY . .
# SECRET_KEY_BASE_DUMMY: ビルド時だけダミーの鍵でアセットをコンパイル（本物の鍵は実行時の環境変数）
RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile

# ---- Litestream（バージョンとチェックサムを固定）----
FROM debian:bookworm-slim AS litestream
ARG LITESTREAM_VERSION=0.5.17
ARG LITESTREAM_SHA256=cfb371176d164437ae869f8351cfde49bd1804ae71c61923f75c9cba9c9c006d
RUN apt-get update -qq && apt-get install --no-install-recommends -y curl ca-certificates && \
    curl -fsSL -o /tmp/ls.tgz "https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-${LITESTREAM_VERSION}-linux-x86_64.tar.gz" && \
    echo "${LITESTREAM_SHA256}  /tmp/ls.tgz" | sha256sum -c - && \
    tar -xzf /tmp/ls.tgz -C /usr/local/bin litestream

# ---- 最終イメージ ----
FROM base
COPY --from=litestream /usr/local/bin/litestream /usr/local/bin/litestream
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# root 以外で実行。/data は永続ボリューム（SQLite と画像）
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p /data && chown -R rails:rails /data db log tmp storage
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
VOLUME /data
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 CMD curl -fs http://localhost:3000/up || exit 1

# Solid Queue は Puma の中で動かす（コンテナ1つ）。Puma はワーカー無し・スレッド少なめ（メモリ 1GB 前提）
ENV SOLID_QUEUE_IN_PUMA=true RAILS_MAX_THREADS=3 WEB_CONCURRENCY=0
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
