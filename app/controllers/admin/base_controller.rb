module Admin
  # 管理画面は韓国語UI固定で、公開サイトの /:locale というURL規則は使いません。
  class BaseController < ApplicationController
    include AdminAuthentication

    layout "admin"

    # 開発中に「一時的な公開リンク」で見せているとき、管理画面は外から開けないようにする
    # （開発用の既定パスワードのままでも、リンクを知った人が管理画面に入れないように）
    before_action :block_admin_over_public_tunnel, if: -> { Rails.env.development? }
    skip_before_action :set_locale
    before_action { I18n.locale = :ko }

    def default_url_options
      {}
    end

    private

    def block_admin_over_public_tunnel
      head :forbidden if request.host.end_with?("trycloudflare.com")
    end
  end
end
