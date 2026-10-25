# ADR 0002: Litestream で S3 にバックアップ / Litestream으로 S3에 백업

状態 / 상태: 採用 / 채택 (2026-10)

## 背景 / 배경
SQLite は「ファイル」なので、ディスクが壊れるとデータが全て消える。スナップショット（日次）では最大1日分を失う。

## 決定 / 결정
- Litestream で primary DB の WAL を約10秒ごとに AWS S3（ソウル）へ複製（GCS も同じ設定で可）。保持期間 72 時間。
- 複製するのは **primary のみ**。cache は再生成できる、queue / cable は一時データのため対象外（`config/litestream.yml`）。
- 認証は **そのバケットだけ**に権限を絞った IAM ユーザーのキー（`.env` に保存。AWS ルートのキーは使わない）。
- コンテナ起動時に DB が無ければ自動で復元（`bin/docker-entrypoint`）。
- **画像ファイル（Active Storage）は Litestream の対象外。** `/var/lib/eunpa/files` を別途バックアップする（Runbook 参照: 日次の `gcloud storage rsync`）。

## 復元テスト / 복원 테스트
`deploy/restore-test.sh` で「ディスク消失 → 再起動 → 自動復元」を実機（Docker）で確認済み。結果は docs/runbook.md に記録。S3 では URL を `s3://...` に変えるだけ（GCS も同様）。

## 代替案 / 대안
- 日次の `sqlite3 .backup` + cron: 最大24時間分の損失。手順が増える。
- Cloud SQL 自動バックアップ: 無料枠なし（ADR 0001）。
