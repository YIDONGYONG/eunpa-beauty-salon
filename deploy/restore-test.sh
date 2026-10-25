#!/usr/bin/env bash
# Litestream の「復元テスト」: 本番イメージを使い、ディスク消失 → レプリカから復元できることを確かめる。
# 複製先はローカルの file:// （S3 / GCS と同じ手順・設定。違うのは URL だけ）。結果は docs/runbook.md に記録する。
#   使い方: deploy/restore-test.sh [イメージ名]   例: deploy/restore-test.sh eunpa-prod
set -euo pipefail
IMAGE="${1:-eunpa-prod}"
NAME=eunpa-restore-test
DATA_VOL=eunpa_restore_data
REPLICA_VOL=eunpa_restore_replica
run_container() {
  docker run -d --name "$NAME" -p 3999:3000 \
    -v "$DATA_VOL":/data -v "$REPLICA_VOL":/replica \
    -e SECRET_KEY_BASE="$(openssl rand -hex 32)" -e FORCE_SSL=false \
    -e ADMIN_EMAIL=admin@example.com -e ADMIN_PASSWORD=restore-test-pass -e RUN_SEED=true \
    -e LITESTREAM_REPLICA_URL=file:///replica/production "$IMAGE" >/dev/null
}
wait_up() { for _ in $(seq 1 60); do curl -fs http://localhost:3999/up >/dev/null && return 0; sleep 2; done; echo "起動しませんでした"; docker logs "$NAME" | tail -30; exit 1; }
cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

cleanup; docker volume rm -f "$DATA_VOL" "$REPLICA_VOL" >/dev/null
docker run --rm -v "$DATA_VOL":/data -v "$REPLICA_VOL":/replica alpine chown -R 1000:1000 /data /replica

echo "1) 初回起動（マイグレーション + シード）"
run_container; wait_up
docker exec "$NAME" bin/rails runner 'Event.create!(title_ko: "복원 테스트 표식"); puts "표식 저장: #{Event.count}건, 글 #{Post.count}건"'
echo "2) レプリケーションを待つ（15秒）"; sleep 15
docker stop "$NAME" >/dev/null; docker rm "$NAME" >/dev/null

echo "3) ディスク消失を再現: データボリュームを削除"
docker volume rm "$DATA_VOL" >/dev/null
docker run --rm -v "$DATA_VOL":/data alpine chown 1000:1000 /data

echo "4) 再起動 → レプリカから自動復元されるはず"
run_container; wait_up
docker logs "$NAME" 2>&1 | grep -i "restor" || true
docker exec "$NAME" bin/rails runner 'ok = Event.exists?(title_ko: "복원 테스트 표식"); puts(ok ? "복원 성공: 표식 확인, 글 #{Post.count}건" : "복원 실패"); exit(ok ? 0 : 1)'
echo "OK: 復元テスト成功"
cleanup
docker volume rm -f "$DATA_VOL" "$REPLICA_VOL" >/dev/null
