#!/usr/bin/env bash
# PreToolUse(Edit|Write): 비밀 값/자동 생성 파일을 실수로 수정하지 못하게 막습니다.
file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0
case "$file" in
  */.env|*/.env.*|*/config/master.key|*/config/credentials/*.key)
    case "$file" in *.env.example) exit 0 ;; esac
    echo "차단: $file 은(는) 비밀 값 파일입니다. 사용자가 직접 수정해야 합니다. (예시는 .env.example 에 적으세요)" >&2
    exit 2 ;;
  */db/schema.rb)
    echo "차단: db/schema.rb 는 자동 생성 파일입니다. 마이그레이션을 추가하고 bin/rails db:migrate 를 실행하세요." >&2
    exit 2 ;;
  */db/migrate/*)
    if [ -f "$file" ]; then
      echo "차단: 이미 만든 마이그레이션은 수정하지 않습니다. 새 마이그레이션을 추가하세요." >&2
      exit 2
    fi ;;
esac
exit 0
