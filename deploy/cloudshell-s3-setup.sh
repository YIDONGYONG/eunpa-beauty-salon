#!/usr/bin/env bash
# AWS の CloudShell（コンソール左下）で実行する。Litestream のバックアップ用に、次の 3 つを作る。
#   1. S3 バケット（ソウル。パブリックアクセスはすべてブロック）
#   2. そのバケットだけを読み書きできる IAM ユーザー `eunpa-litestream`
#   3. そのユーザーのアクセスキー（画面に 1 回だけ表示。サーバーの .env にだけ入れる）
# 使い方: CloudShell で
#   curl -fsSL https://raw.githubusercontent.com/YIDONGYONG/eunpa-beauty-salon/main/deploy/cloudshell-s3-setup.sh | bash
set -euo pipefail

REGION=ap-northeast-2
BUCKET="${BUCKET:-eunpa-backup-$(openssl rand -hex 4)}"   # バケット名は世界で一意にする必要がある
USER_NAME=eunpa-litestream

aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  --create-bucket-configuration "LocationConstraint=$REGION" >/dev/null
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

cat > /tmp/eunpa-policy.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["s3:ListBucket", "s3:GetBucketLocation"], "Resource": "arn:aws:s3:::$BUCKET" },
    { "Effect": "Allow", "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], "Resource": "arn:aws:s3:::$BUCKET/*" }
  ]
}
POLICY

aws iam create-user --user-name "$USER_NAME" >/dev/null
aws iam put-user-policy --user-name "$USER_NAME" --policy-name eunpa-litestream-s3 \
  --policy-document file:///tmp/eunpa-policy.json
KEYS=$(aws iam create-access-key --user-name "$USER_NAME" \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)
rm -f /tmp/eunpa-policy.json

echo
echo "================ 完了 ================"
echo "バケット名             : $BUCKET   （公開してよい値）"
echo "アクセスキー ID         : $(echo "$KEYS" | cut -f1)"
echo "シークレットアクセスキー : $(echo "$KEYS" | cut -f2)"
echo "======================================="
echo "上の 3 つを、サーバーで bootstrap.sh を実行したときの質問に入力する。"
echo "キーはこの画面にしか表示されない。チャットや GitHub には貼らないこと。"
