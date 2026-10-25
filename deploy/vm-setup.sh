#!/usr/bin/env bash
# 新しい VM（Debian / Ubuntu）の初期設定。root で 1 回だけ実行する。
#  - スワップ 2GB（メモリ 1GB の保険）  - Docker のインストール  - データ用ディレクトリ
# ビルドは行わない。イメージは GitHub Actions が作り、ここでは pull するだけ。
set -euo pipefail

if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl vm.swappiness=10 && echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
fi

command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh

mkdir -p /opt/eunpa /var/lib/eunpa
chown -R 1000:1000 /var/lib/eunpa       # コンテナの rails ユーザー(UID 1000)が書き込めるように
echo "完了。/opt/eunpa に compose.production.yml と .env を置いてください。"
