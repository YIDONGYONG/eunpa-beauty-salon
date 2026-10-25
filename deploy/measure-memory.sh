#!/usr/bin/env bash
# 1GB メモリの VM を想定して、本番イメージのメモリ使用量を測る（メモリ上限 700MB を付けて実行）。
#   使い方: deploy/measure-memory.sh [イメージ名]
# 見るところ: 起動直後 / アクセス 200 回後の MEM USAGE。上限(700MiB)の 70% 未満なら余裕があります。
set -euo pipefail
IMAGE="${1:-eunpa-prod}"; NAME=eunpa-memtest
trap 'docker rm -f $NAME >/dev/null 2>&1 || true' EXIT
docker rm -f $NAME >/dev/null 2>&1 || true
docker run -d --name $NAME -p 3998:3000 --memory=700m --memory-swap=700m \
  -e SECRET_KEY_BASE="$(openssl rand -hex 32)" -e FORCE_SSL=false -e RUN_SEED=true \
  -e ADMIN_EMAIL=admin@example.com -e ADMIN_PASSWORD=memory-test-pass "$IMAGE" >/dev/null
for _ in $(seq 1 60); do curl -fs http://localhost:3998/up >/dev/null && break; sleep 2; done
echo "起動直後:"; docker stats --no-stream --format '  MEM {{.MemUsage}} ({{.MemPerc}})  CPU {{.CPUPerc}}' $NAME
for _ in $(seq 1 200); do for p in /ko /ko/about /ko/blog /ko/location /en; do curl -s -o /dev/null "http://localhost:3998$p"; done; done
echo "1000 リクエスト後:"; docker stats --no-stream --format '  MEM {{.MemUsage}} ({{.MemPerc}})  CPU {{.CPUPerc}}' $NAME
