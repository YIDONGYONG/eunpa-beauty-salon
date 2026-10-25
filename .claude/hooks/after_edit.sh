#!/usr/bin/env bash
# PostToolUse(Edit|Write): 編集したファイルをすぐに点検します。問題があれば Claude に知らせます（exit 2）。
# Ruby は Docker コンテナの中で実行します（ローカルの Ruby のバージョンに依存しません）。
cd "$CLAUDE_PROJECT_DIR" || exit 0
file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0
rel="${file#$CLAUDE_PROJECT_DIR/}"

run() { docker compose run --rm --no-deps -T web "$@"; }

case "$rel" in
  *.rb|*.rake|Gemfile)
    out=$(run bundle exec rubocop -a -f simple "$rel" 2>&1) || { echo "$out" >&2; exit 2; } ;;
  config/locales/*.yml|app/views/*.erb|app/views/**/*.erb)
    out=$(run env RAILS_ENV=test bin/rails test test/i18n_consistency_test.rb 2>&1) || { echo "$out" | tail -25 >&2; exit 2; } ;;
esac
exit 0
