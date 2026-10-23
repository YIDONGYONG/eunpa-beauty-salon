class SitemapsController < ApplicationController
  skip_before_action :set_locale

  def show
    @locales = I18n.available_locales
    @paths = %w[/ /about /blog /location]
    @posts = Post.published.latest
    expires_in 1.hour, public: true
    respond_to :xml
  end
end
