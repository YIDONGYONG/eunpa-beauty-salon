#!/usr/bin/env bash
# AWS の CloudShell（コンソール左下）で実行する。Litestream のバックアップ用に、次の 3 つを用意する。
#   1. S3 バケット（ソウル。パブリックアクセスはすべてブロック）
#   2. そのバケットだけを読み書きできる IAM ユーザー `eunpa-litestream`
#   3. そのユーザーのアクセスキー（画面に 1 回だけ表示。サーバーの .env にだけ入れる）
# 何度実行しても安全（再実行できる）:
#   - eunpa-backup- で始まるバケットがすでに 1 つあれば、それを使う（なければ新しく作る）
#   - IAM ユーザーがすでにあれば作り直さず、古いアクセスキーを削除して新しいキーを作る
#   - バケットが 2 つ以上ある場合は、使うものを BUCKET=名前 で指定するよう案内して止まる
# 使い方: CloudShell で
#   curl -fsSL https://raw.githubusercontent.com/YIDONGYONG/eunpa-beauty-salon/main/deploy/cloudshell-s3-setup.sh | bash
# バケットを指定する場合:
#   curl -fsSL https://raw.githubusercontent.com/YIDONGYONG/eunpa-beauty-salon/main/deploy/cloudshell-s3-setup.sh | BUCKET=バケット名 bash
set -euo pipefail

REGION=ap-northeast-2
USER_NAME=eunpa-litestream

# --- バケットを決める ---
if [ -z "${BUCKET:-}" ]; then
  EXISTING=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'eunpa-backup-')].Name" --output text)
  COUNT=$(echo "$EXISTING" | wc -w)
  if [ "$COUNT" -eq 0 ]; then
    BUCKET="eunpa-backup-$(openssl rand -hex 4)"   # バケット名は世界で一意にする必要がある
  elif [ "$COUNT" -eq 1 ]; then
    BUCKET=$EXISTING
    echo "既存のバケットを使います: $BUCKET"
  else
    echo "eunpa-backup- で始まるバケットが複数あります: $EXISTING"
    echo "使うものを BUCKET=名前 で指定して、もう一度実行してください。"
    echo "不要な空のバケットは次のコマンドで削除できます（中身があると削除されません）:"
    echo "  aws s3 rb s3://不要なバケット名"
    exit 1
  fi
fi

if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration "LocationConstraint=$REGION" >/dev/null
fi
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# --- 権限（このバケットだけ）---
cat > /tmp/eunpa-policy.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["s3:ListBucket", "s3:GetBucketLocation"], "Resource": "arn:aws:s3:::$BUCKET" },
    { "Effect": "Allow", "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], "Resource": "arn:aws:s3:::$BUCKET/*" }
  ]
}
POLICY

# --- IAM ユーザー（あれば再利用）---
if aws iam get-user --user-name "$USER_NAME" >/dev/null 2>&1; then
  echo "既存の IAM ユーザー $USER_NAME を使います（古いアクセスキーは削除します）。"
  for OLD in $(aws iam list-access-keys --user-name "$USER_NAME" --query 'AccessKeyMetadata[].AccessKeyId' --output text); do
    aws iam delete-access-key --user-name "$USER_NAME" --access-key-id "$OLD"
  done
else
  aws iam create-user --user-name "$USER_NAME" >/dev/null
fi
aws iam put-user-policy --user-name "$USER_NAME" --policy-name eunpa-litestream-s3 \
  --policy-document file:///tmp/eunpa-policy.json
KEYS=$(aws iam create-access-key --user-name "$USER_NAME" \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)
rm -f /tmp/eunpa-policy.json

echo
echo "================ DONE ================"
echo "Bucket name       : $BUCKET   (not secret)"
echo "Access key ID     : $(echo "$KEYS" | cut -f1)"
echo "Secret access key : $(echo "$KEYS" | cut -f2)"
echo "======================================="
echo "Enter these 3 values when bootstrap.sh asks on the server."
echo "The secret key is shown only once. Do not paste it in chat or GitHub."
