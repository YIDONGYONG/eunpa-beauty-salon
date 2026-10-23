#!/usr/bin/env bash
# PostToolUse(Edit|Write): 수정한 파일을 바로 점검합니다. 문제가 있으면 Claude에게 알려 줍니다(exit 2).
cd "$CLAUDE_PROJECT_DIR" || exit 0
file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0
rel="${file#$CLAUDE_PROJECT_DIR/}"

case "$rel" in
  *.rb|*.rake|Gemfile)
    out=$(bundle exec rubocop -a -f simple "$rel" 2>&1) || { echo "$out" >&2; exit 2; } ;;
  config/locales/*.yml|app/views/*.erb|app/views/**/*.erb)
    out=$(bin/rails test test/i18n_consistency_test.rb 2>&1) || { echo "$out" | tail -25 >&2; exit 2; } ;;
esac
exit 0
