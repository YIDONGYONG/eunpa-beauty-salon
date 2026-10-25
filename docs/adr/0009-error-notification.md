# ADR 0009: 例外はメールで通知（gem なし）/ 예외는 이메일로 알림

状態 / 상태: 採用 / 채택 (2026-10)

## 決定 / 결정
`Rails.error` の購読者（`config/initializers/error_notifier.rb`）で、未処理の例外を SMTP メールで `ERROR_NOTIFY_EMAIL` に送る。同種のエラーは10分に1回まで。`ERROR_NOTIFY_EMAIL` と `SMTP_ADDRESS` が未設定なら何もしない。

## 理由 / 이유
無料の監視（UptimeRobot で `/up`）は「落ちたか」しか分からない。500 エラーの原因は通知が必要。Sentry 等は無料枠・外部送信・設定が増える。まずは最小で。

## 限界 / 한계
メール送信自体が失敗すると通知されない。ログは `docker logs`（json-file 10MB×3）に残る。
