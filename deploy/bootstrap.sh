#!/usr/bin/env bash
# 初回のデプロイを、サーバー（Lightsail の Ubuntu）の上で対話的に行うスクリプト。
#  1. GitHub から compose.yaml と Caddyfile を取得
#  2. 質問に答えるだけで .env を作成（秘密の値は画面に表示せず、チャットなどにも送らない）
#  3. イメージを pull してコンテナを起動
# 使い方（サーバーの ubuntu ユーザーで実行。vm-setup.sh が済んでいること）:
#   curl -fsSL https://raw.githubusercontent.com/YIDONGYONG/eunpa-beauty-salon/main/deploy/bootstrap.sh -o /tmp/bootstrap.sh && bash /tmp/bootstrap.sh
set -euo pipefail

BASE="https://raw.githubusercontent.com/YIDONGYONG/eunpa-beauty-salon/main/deploy"
APP_DIR=/opt/eunpa
cd "$APP_DIR"

if ! docker ps >/dev/null 2>&1; then
  echo "docker を使えません。ターミナルを閉じて開き直してから、もう一度実行してください。" >&2
  exit 1
fi

# --- 1. ファイルの取得 ---
curl -fsSL "$BASE/compose.production.yml" -o compose.yaml
curl -fsSL "$BASE/Caddyfile" -o Caddyfile
echo "compose.yaml と Caddyfile を取得しました。"

# --- 2. .env の作成 ---
if [ -f .env ]; then
  read -r -p ".env がすでにあります。上書きしますか？ (yes/no): " ans
  [ "$ans" = "yes" ] || { echo ".env を残したまま、起動だけ行います。"; SKIP_ENV=1; }
fi

if [ -z "${SKIP_ENV:-}" ]; then
  # 値に使えない文字（空白・引用符・$ など）を弾く（.env と compose の解釈で壊れるため）
  ask() {  # ask 変数名 "質問" [secret]
    local name=$1 prompt=$2 secret=${3:-} value
    while true; do
      if [ "$secret" = secret ]; then read -r -s -p "$prompt: " value; echo; else read -r -p "$prompt: " value; fi
      if [ -z "$value" ]; then echo "  入力が空です。もう一度。"; continue; fi
      if [[ "$value" =~ [[:space:]\$\"\'\`\\] ]]; then echo "  空白と \$ \" ' \` \\ は使えません。もう一度。"; continue; fi
      printf -v "$name" '%s' "$value"; return
    done
  }

  echo
  echo "管理画面のログイン情報を決めます（パスワードは 16 文字以上を推奨）。"
  ask ADMIN_EMAIL "管理者のメールアドレス"
  ask ADMIN_PASSWORD "管理者のパスワード（入力しても表示されません）" secret
  echo
  echo "S3 のバックアップ先を入力します（CloudShell のスクリプトが表示した値）。"
  ask BUCKET "S3 バケット名"
  ask LS_KEY_ID "アクセスキー ID" secret
  ask LS_SECRET "シークレットアクセスキー（入力しても表示されません）" secret

  SECRET_KEY_BASE=$(openssl rand -hex 64)
  umask 077
  cat > .env <<EOF
# 本番の環境変数（このファイルはリポジトリに入れない。bootstrap.sh が作成）
IMAGE=ghcr.io/yidongyong/eunpa-beauty-salon
SECRET_KEY_BASE=$SECRET_KEY_BASE
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD
RUN_SEED=true
APP_HOST=eunpabeautysalon.duckdns.org
APP_BASE_URL=https://eunpabeautysalon.duckdns.org
FORCE_SSL=true
LITESTREAM_REPLICA_URL=s3://$BUCKET/eunpa/production
LITESTREAM_ACCESS_KEY_ID=$LS_KEY_ID
LITESTREAM_SECRET_ACCESS_KEY=$LS_SECRET
AWS_REGION=ap-northeast-2
NAVER_SITE_VERIFICATION=
GOOGLE_SITE_VERIFICATION=
NAVER_MAP_CLIENT_ID=
NAVER_APP_NAME=kr.eunpa.salon
ERROR_NOTIFY_EMAIL=
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
MAIL_FROM=noreply@example.com
UPLOAD_MAX_MB=5
IMAGE_MAX_EDGE=1600
IMAGE_QUALITY=82
EOF
  chmod 600 .env
  echo ".env を作成しました（権限 600）。"
fi

# --- 3. 起動 ---
docker compose pull
docker compose up -d
sleep 20
docker compose ps
echo
echo "--- アプリのログ（末尾） ---"
docker logs --tail 25 eunpa-web-1 || true
echo
echo "次: 数分待ってから https://eunpabeautysalon.duckdns.org/up を開く。"
echo "表示できたら、.env の RUN_SEED を false にして 'docker compose up -d' を実行する。"
