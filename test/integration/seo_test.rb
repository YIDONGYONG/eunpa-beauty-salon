require "test_helper"

# 検索エンジン向けの情報（構造化データ・説明文）が、期待どおりに出力されることを確認する。
class SeoTest < ActionDispatch::IntegrationTest
  setup do
    SiteSetting.instance.update!(phone: "054-535-6353", address_ko: "경상북도 상주시 왕산로 160", region_name_ko: "상주",
                                 latitude: 36.41, longitude: 128.16, schema_hours: "Mo-Sa 09:00-19:00")
    category = MenuCategory.create!(name_ko: "커트")
    category.menu_items.create!(name_ko: "여성 커트", price: 13_000)
    category.menu_items.create!(name_ko: "혼주화장", price: 150_000)
    category.menu_items.create!(name_ko: "숨김 메뉴", price: 1_000, visible: false)
    @post = Post.create!(title_ko: "첫 글", content_ko: "<p>본문</p>", published: true)
  end

  def json_ld(selector_index = 0)
    scripts = css_select('script[type="application/ld+json"]')
    JSON.parse(scripts[selector_index].text)
  end

  test "home JSON-LD describes the salon with international phone, price range and address parts" do
    get "/ko"
    data = json_ld
    assert_equal "HairSalon", data["@type"]
    assert_equal "+82-54-535-6353", data["telephone"]
    assert_equal "KRW 13,000-150,000", data["priceRange"] # 非表示の価格は含めない
    assert_equal "상주", data.dig("address", "addressLocality")
    assert_equal "KR", data.dig("address", "addressCountry")
    assert data["image"].end_with?("/og-image.png")
    assert data["hasMap"].start_with?("https://map.naver.com/")
    assert_nil data["potentialAction"], "予約ページの URL がなければ予約の情報は出さない"
  end

  test "reserve action appears only when the NAVER booking url is set" do
    SiteSetting.instance.update!(naver_booking_url: "https://booking.naver.com/booking/13/bizes/1")
    get "/ko"
    action = json_ld["potentialAction"]
    assert_equal "ReserveAction", action["@type"]
    assert_equal "https://booking.naver.com/booking/13/bizes/1", action["target"]
  end

  test "blog post page has a BlogPosting JSON-LD after the salon one" do
    get "/ko/blog/#{@post.id}"
    article = css_select('script[type="application/ld+json"]').map { |s| JSON.parse(s.text) }.find { |d| d["@type"] == "BlogPosting" }
    assert_not_nil article
    assert_equal "첫 글", article["headline"]
    assert_equal "ko", article["inLanguage"]
    assert article["mainEntityOfPage"].end_with?("/ko/blog/#{@post.id}")
  end

  test "sub page descriptions mention the region in every language" do
    { "ko" => "상주", "en" => "Sangju", "ja" => "尚州" }.each do |locale, region|
      %w[about blog location].each do |page|
        get "/#{locale}/#{page}"
        assert_select 'meta[name="description"][content*=?]', region, 1, "#{locale}/#{page} の説明文に地域名がない"
      end
    end
  end

  test "phone_e164 handles Seoul, regional and mobile numbers" do
    helper = ApplicationController.helpers
    assert_equal "+82-2-1234-5678", helper.phone_e164("02-1234-5678")
    assert_equal "+82-54-535-6353", helper.phone_e164("054-535-6353")
    assert_equal "+82-10-1234-5678", helper.phone_e164("010-1234-5678")
    assert_nil helper.phone_e164("")
  end
end
