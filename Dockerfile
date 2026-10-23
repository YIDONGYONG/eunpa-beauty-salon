# 開発用イメージ（本番用の設定はサーバーが決まってから追加します）
ARG RUBY_VERSION=3.2.2
FROM ruby:${RUBY_VERSION}-slim

ENV LANG=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    RAILS_ENV=development

# libpq: PostgreSQL / libvips: 画像リサイズ（Active Storage）/ curl: ヘルスチェック
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git curl libpq-dev libvips libyaml-dev pkg-config postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN chmod +x bin/* bin/docker-entrypoint

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
