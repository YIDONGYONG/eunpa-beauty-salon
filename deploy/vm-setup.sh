#!/usr/bin/env bash
# 新しい VM（Debian / Ubuntu）の初期設定。root で 1 回だけ実行する。
#  - スワップ 2GB（メモリ 1GB の保険）  - Docker のインストール  - データ用ディレクトリ
#  - OS のセキュリティ更新の自動適用（unattended-upgrades）
#  - 配備用ユーザー（既定は ubuntu。DEPLOY_USER で変更）を docker グループへ追加
# ビルドは行わない。イメージは GitHub Actions が作り、ここでは pull するだけ。
set -euo pipefail

if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl vm.swappiness=10 && echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
fi

command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh

# OS のセキュリティ更新を自動で適用する（パッチ漏れを防ぐ）
if command -v apt-get >/dev/null; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades >/dev/null
fi

# GitHub Actions の配備（SSH 経由の docker compose）で sudo なしに docker を使えるようにする
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"
if id "$DEPLOY_USER" >/dev/null 2>&1; then
  usermod -aG docker "$DEPLOY_USER"
fi

mkdir -p /opt/eunpa /var/lib/eunpa
chown -R 1000:1000 /var/lib/eunpa       # コンテナの rails ユーザー(UID 1000)が書き込めるように
if id "$DEPLOY_USER" >/dev/null 2>&1; then chown "$DEPLOY_USER": /opt/eunpa; fi   # .env などを置けるように
echo "完了。/opt/eunpa に compose.production.yml と .env を置いてください。"
