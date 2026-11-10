#!/usr/bin/env bash
# AWS の CloudShell で実行する。Lightsail の不要なインスタンスと固定 IP を、すべてのリージョンから探して整理する。
#   残すもの: ソウル(ap-northeast-2)のインスタンス eunpa-web と、固定 IP eunpa-ip（本番サイト）
#   消す候補: それ以外のインスタンス、インスタンスにつながっていない固定 IP
#   スナップショットは一覧を表示するだけで、自動では消さない。
# 既定は「確認だけ」（何も消さない）。消すときは CONFIRM=yes を付けて、もう一度実行する。
#   確認: curl -fsSL https://raw.githubusercontent.com/YIDONGYONG/eunpa-beauty-salon/main/deploy/cloudshell-cleanup.sh | bash
#   削除: curl -fsSL https://raw.githubusercontent.com/YIDONGYONG/eunpa-beauty-salon/main/deploy/cloudshell-cleanup.sh | CONFIRM=yes bash
set -euo pipefail

KEEP_REGION=ap-northeast-2
KEEP_INSTANCE=eunpa-web
KEEP_IP=eunpa-ip
CONFIRM="${CONFIRM:-no}"

if [ "$CONFIRM" = yes ]; then echo "=== MODE: DELETE ==="; else echo "=== MODE: CHECK ONLY (nothing will be deleted) ==="; fi

FOUND_KEEP=no
for R in $(aws lightsail get-regions --query 'regions[].name' --output text); do
  INSTANCES=$(aws lightsail get-instances --region "$R" --query 'instances[].name' --output text 2>/dev/null || true)
  IPS=$(aws lightsail get-static-ips --region "$R" --query 'staticIps[].[name,isAttached]' --output text 2>/dev/null || true)
  SNAPS=$(aws lightsail get-instance-snapshots --region "$R" --query 'instanceSnapshots[].name' --output text 2>/dev/null || true)
  [ -z "$INSTANCES$IPS$SNAPS" ] && continue
  echo
  echo "--- $R"
  for N in $INSTANCES; do
    if [ "$R" = "$KEEP_REGION" ] && [ "$N" = "$KEEP_INSTANCE" ]; then
      echo "KEEP    instance  $N"; FOUND_KEEP=yes; continue
    fi
    if [ "$CONFIRM" = yes ]; then
      aws lightsail delete-instance --region "$R" --instance-name "$N" >/dev/null && echo "DELETED instance  $N"
    else
      echo "DELETE? instance  $N"
    fi
  done
  while read -r IPNAME ATTACHED; do
    [ -z "${IPNAME:-}" ] && continue
    if [ "$R" = "$KEEP_REGION" ] && [ "$IPNAME" = "$KEEP_IP" ]; then echo "KEEP    static-ip $IPNAME"; continue; fi
    if [ "$ATTACHED" = True ] || [ "$ATTACHED" = true ]; then
      echo "KEEP    static-ip $IPNAME (attached to an instance; deleting the instance detaches it, run again afterwards)"; continue
    fi
    if [ "$CONFIRM" = yes ]; then
      aws lightsail release-static-ip --region "$R" --static-ip-name "$IPNAME" >/dev/null && echo "DELETED static-ip $IPNAME"
    else
      echo "DELETE? static-ip $IPNAME (not attached)"
    fi
  done <<< "$IPS"
  for S in $SNAPS; do echo "INFO    snapshot  $S (not deleted automatically; review in the console)"; done
done

echo
if [ "$FOUND_KEEP" != yes ]; then
  echo "!! WARNING: $KEEP_INSTANCE was not found in $KEEP_REGION in this account. Nothing was deleted by mistake, but check which AWS account you are in."
  exit 1
fi
echo "Done. $KEEP_INSTANCE (Seoul) is kept."
[ "$CONFIRM" = yes ] || echo "To delete the 'DELETE?' items above, run again with CONFIRM=yes."
