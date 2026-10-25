# 本番で例外が起きたとき、原長ではなく管理者（開発者）にメールで知らせる（ADR 0009）
class ErrorMailer < ApplicationMailer
  def notify(summary)
    @summary = summary
    mail to: ENV.fetch("ERROR_NOTIFY_EMAIL"), subject: "[은파미용실] 오류: #{summary[:class]}"
  end
end
