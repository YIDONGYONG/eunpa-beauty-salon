#!/bin/sh
# Lightsail の「起動スクリプト（Launch script）」欄に、このファイルの内容を貼り付ける。
# インスタンスの作成直後に root で 1 回だけ実行され、サーバーの初期設定（スワップ・Docker・ディレクトリ）が済む。
# 手順は deploy/vm-setup.sh と同じ。リポジトリの最新版を取得して実行する（リポジトリは公開）。
# 注意: Lightsail は起動スクリプトを bash ではなく sh（dash）で実行することがあるため、
#       ここでは bash 専用の書き方（set -o pipefail など）を使わず、本体の vm-setup.sh だけを bash で実行する。
set -eu
export DEPLOY_USER=ubuntu
curl -fsSL https://raw.githubusercontent.com/YIDONGYONG/eunpa-beauty-salon/main/deploy/vm-setup.sh -o /root/vm-setup.sh
bash /root/vm-setup.sh > /var/log/eunpa-setup.log 2>&1
