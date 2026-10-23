class ApplicationController < ActionController::Base
  # モダンブラウザのみ許可（モバイル優先のサイトだが、古いブラウザでも読めるようデフォルトを維持）
  allow_browser versions: :modern

  before_action :set_locale

  helper_method :site_setting, :owner_profile, :locale_path_for

  # すべてのリンクに現在の言語（/ko、/en ...）を自動で付けます。
  def default_url_options
    { locale: I18n.locale }
  end

  private

  def set_locale
    requested = params[:locale].to_s
    locale = I18n.available_locales.map(&:to_s).include?(requested) ? requested : I18n.default_locale.to_s
    I18n.locale = locale
    # 選択した言語は Cookie に保存されます。
    if cookies[:locale] != locale
      cookies.permanent[:locale] = { value: locale, same_site: :lax }
    end
  end

  def site_setting
    @site_setting ||= SiteSetting.instance
  end

  def owner_profile
    @owner_profile ||= OwnerProfile.instance
  end

  # 同じページを別の言語で見るURL（言語選択／hreflang 用）
  def locale_path_for(locale)
    url_for(locale: locale, only_path: true)
  end
end
