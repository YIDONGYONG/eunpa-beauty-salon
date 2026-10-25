# ADR 0004: 本番は Docker（Rails+Litestream コンテナ + Caddy）/ 운영은 Docker

状態 / 상태: 採用 / 채택 (2026-10)

## 決定 / 결정
- 本番は Rails+Litestream の **コンテナ1つ**（+ HTTPS 用の Caddy。DuckDNS は Cloudflare の背後に置けないため）: Puma（ワーカー無し・スレッド3）の中で Solid Queue を動かし（`SOLID_QUEUE_IN_PUMA`）、`litestream replicate -exec` が Rails を子プロセスとして起動する。
- **ビルドは GitHub Actions**（テスト → イメージ作成 → GHCR へ push）。VM では `docker compose pull && up -d` だけ。1GB の VM で `docker build` や `assets:precompile` を実行しない。
- イメージは multi-stage（コンパイラは最終イメージに入れない）、非 root（UID 1000）、`libjemalloc2` でメモリ断片化を抑える。`config/master.key` は `.dockerignore` で除外（イメージに秘密を入れない）。
- 秘密値は VM の `.env`（`deploy/env.production.example`）と GitHub Secrets のみ。

## 代替案 / 대안
| 案 | 理由 |
|---|---|
| Kamal | 強力だが、1VM・1コンテナには機能過多。学習コストと依存が増える |
| Kubernetes / Cloud Run | コスト・複雑さが目的に合わない（Cloud Run は SQLite の永続化と相性が悪い） |
| VM に直接 Ruby を入れる | 環境差・パッチ管理が属人化する |

## メモリ実測 / 메모리 실측
`deploy/measure-memory.sh`（メモリ上限 700MB）: 起動直後 約 214MB、1000 リクエスト後 約 266MB。
