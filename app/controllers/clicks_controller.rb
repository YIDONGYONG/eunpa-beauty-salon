# 「電話」「道案内」などのボタンのクリック数を記録する（navigator.sendBeacon から呼ばれる）。
# 保存するのは種類・言語・ページ名だけ。Cookie・IP・端末情報は保存しない。
class ClicksController < ApplicationController
  skip_before_action :set_locale
  skip_forgery_protection # 個人情報のない件数記録のみ。sendBeacon は CSRF トークンを付けられない

  def create
    ClickEvent.create(kind: params[:kind].to_s, locale: params[:lang].to_s.presence_in(%w[ko en]) || "ko",
                      page: params[:page].to_s.first(40), created_at: Time.current)
    head :no_content
  end
end
