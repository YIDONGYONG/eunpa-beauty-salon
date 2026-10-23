base = ENV["APP_BASE_URL"].presence || request.base_url
xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9",
           "xmlns:xhtml" => "http://www.w3.org/1999/xhtml" do
  entries = @paths.map { |path| [ path, nil ] } + @posts.map { |post| [ "/blog/#{post.id}", post.updated_at ] }
  entries.each do |path, lastmod|
    @locales.each do |locale|
      xml.url do
        xml.loc "#{base}/#{locale}#{path == '/' ? '' : path}"
        xml.lastmod lastmod.iso8601 if lastmod
        @locales.each do |alt|
          xml.xhtml :link, rel: "alternate", hreflang: alt.to_s,
                           href: "#{base}/#{alt}#{path == '/' ? '' : path}"
        end
      end
    end
  end
end
