module Admin
  # 管理画面は韓国語UI固定で、公開サイトの /:locale というURL規則は使いません。
  class BaseController < ApplicationController
    include AdminAuthentication

    layout "admin"
    skip_before_action :set_locale
    before_action { I18n.locale = :ko }

    def default_url_options
      {}
    end
  end
end
