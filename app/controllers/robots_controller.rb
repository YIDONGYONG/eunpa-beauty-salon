class RobotsController < ApplicationController
  skip_before_action :set_locale

  def show
    render plain: <<~TXT, content_type: "text/plain"
      User-agent: *
      Disallow: /admin
      Allow: /

      Sitemap: #{base_url}/sitemap.xml
    TXT
  end

  private

  def base_url
    ENV["APP_BASE_URL"].presence || request.base_url
  end
end
