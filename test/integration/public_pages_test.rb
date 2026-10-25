require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  setup do
    SiteSetting.instance.update!(phone: "02-1234-5678", address_ko: "서울 어딘가 1", latitude: 37.5, longitude: 127.0)
    cut = create_category("커트", name_en: "Haircut")
    create_item(cut, "여성 커트", 30_000, name_en: "Women's haircut")
    create_item(cut, "파마 시작", 40_000, price_from: true)
    create_item(cut, "숨김 메뉴", 1_000, visible: false)
    @post = Post.create!(title_ko: "첫 글", title_en: "First post", content_ko: "<p>본문</p>", published: true)
    @draft = Post.create!(title_ko: "임시 글", published: false)
  end

  test "both locales render every public page" do
    %w[ko en].each do |locale|
      [ "/#{locale}", "/#{locale}/about", "/#{locale}/blog", "/#{locale}/blog/#{@post.id}", "/#{locale}/location", "/#{locale}/privacy" ].each do |path|
        get path
        assert_response :success, "#{path} should render"
        assert_select "html[lang=?]", locale
      end
    end
  end

  test "root redirects using cookie, then browser language, then Korean" do
    get "/", headers: { "Accept-Language" => "ja,en;q=0.8" }
    assert_redirected_to "/en"

    get "/", headers: { "Accept-Language" => "fr" }
    assert_redirected_to "/ko"

    get "/en"
    get "/"
    assert_redirected_to "/en"
  end

  test "selected language is saved in a cookie" do
    get "/en"
    assert_equal "en", cookies[:locale]
  end

  test "home shows prices in 30,000원 format and hides hidden items" do
    get "/ko"
    assert_select ".price-value", text: "30,000원"
    assert_select ".price-value", text: "40,000원부터"
    assert_select ".price-name", text: "숨김 메뉴", count: 0
  end

  test "home shows translated names, falling back to Korean" do
    get "/en"
    assert_select ".price-card-title", text: "Haircut"
    assert_select ".price-name", text: "Women's haircut"
    assert_select ".price-name", text: "파마 시작" # 英語の翻訳がなければ韓国語
  end

  test "language switcher links to the same page in each language" do
    get "/en/blog"
    assert_select ".lang-switcher a[href=?]", "/ko/blog"
    assert_select ".lang-switcher a[href=?]", "/en/blog"
  end

  test "pages include hreflang alternates and meta description" do
    get "/ko/about"
    assert_select "link[rel=alternate][hreflang]", count: 3 # 2言語 + x-default
    assert_select "meta[name=description][content]"
    assert_select "meta[property='og:title']"
  end

  test "unpublished posts are not visible" do
    get "/ko/blog"
    assert_select ".post-card-title", text: "첫 글"
    assert_select ".post-card-title", text: "임시 글", count: 0
    get "/ko/blog/#{@draft.id}"
    assert_response :not_found
  end

  test "location page exposes phone link and map data" do
    get "/ko/location"
    assert_select "a[href=?]", "tel:0212345678"
    assert_select "[data-controller=naver-map][data-naver-map-lat-value]"
    assert_select "[data-controller=navi][data-navi-app-url-value^='nmap://navigation']"
  end

  test "sitemap lists every language and robots.txt blocks admin" do
    get "/sitemap.xml"
    assert_response :success
    %w[ko en].each { |l| assert_includes response.body, "/#{l}/blog/#{@post.id}" }
    get "/robots.txt"
    assert_includes response.body, "Disallow: /admin"
    assert_includes response.body, "sitemap.xml"
  end
end
