# 「/」にアクセスしたら、Cookie → ブラウザの言語 → 韓国語の順で言語を決め、/ko などへ転送します。
class LocaleRedirectsController < ApplicationController
  skip_before_action :set_locale

  def show
    redirect_to root_path(locale: preferred_locale), status: :found
  end

  private

  def preferred_locale
    available = I18n.available_locales.map(&:to_s)
    return cookies[:locale] if available.include?(cookies[:locale])

    header = request.headers["Accept-Language"].to_s
    header.split(",").filter_map { |part| part.split(";").first.to_s.strip[0, 2] }
          .find { |code| available.include?(code) } || I18n.default_locale.to_s
  end
end
