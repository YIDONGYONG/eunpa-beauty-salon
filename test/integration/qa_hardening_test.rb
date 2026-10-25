require "test_helper"

# 品質・セキュリティの「厳しめ」チェック。境界値・悪意のある入力・空データ・権限を確かめる。
class QaHardeningTest < ActionDispatch::IntegrationTest
  # ---------- 権限: 未ログインでは管理画面の全ルートに入れない ----------
  test "every admin route redirects to login when not signed in" do
    admin_routes = Rails.application.routes.routes.filter_map do |r|
      path = r.path.spec.to_s.sub("(.:format)", "")
      next unless path.start_with?("/admin") && !path.start_with?("/admin/login") && path != "/admin/session"

      [ r.verb, path.gsub(/:\w+/, "1") ]
    end
    assert_operator admin_routes.size, :>=, 20, "管理画面のルートが見つからない"

    admin_routes.each do |verb, path|
      process verb.downcase.to_sym, path
      assert_response :redirect, "#{verb} #{path} は未ログインで拒否されるべき"
      assert_redirected_to admin_login_path, "#{verb} #{path}"
    end
  end

  test "unauthenticated writes change nothing" do
    create_category("커트")
    assert_no_difference [ "MenuCategory.count", "Post.count", "Event.count" ] do
      post admin_menu_categories_path, params: { menu_category: { name_ko: "침입" } }
      post admin_posts_path, params: { post: { title_ko: "침입" } }
      post admin_events_path, params: { event: { title_ko: "침입" } }
    end
  end

  test "logout ends the session" do
    sign_in_admin
    get admin_root_path
    assert_response :success
    delete admin_session_path
    get admin_root_path
    assert_redirected_to admin_login_path
  end

  test "wrong password and unknown user get the same generic error" do
    create_admin
    post admin_session_path, params: { email: "owner@example.com", password: "wrong" }
    first = response.body[/flash[^>]*>[^<]+/]
    post admin_session_path, params: { email: "nobody@example.com", password: "wrong" }
    assert_response :unprocessable_entity
    assert_equal first, response.body[/flash[^>]*>[^<]+/], "ユーザーの有無が分かるメッセージの違いがある"
  end

  test "admin email is normalized (case and spaces)" do
    create_admin
    post admin_session_path, params: { email: "  OWNER@Example.com ", password: ADMIN_PASSWORD }
    assert_redirected_to admin_root_path
  end

  test "forgery protection rejects admin posts without a token" do
    create_admin
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    begin
      post admin_session_path, params: { email: "owner@example.com", password: ADMIN_PASSWORD }
      assert_response :unprocessable_entity
    ensure
      ActionController::Base.allow_forgery_protection = original
    end
  end

  # ---------- URL・パラメータの境界値 ----------
  test "unknown locale and unknown paths return 404" do
    get "/fr"
    assert_response :not_found
    get "/ko/nothing-here"
    assert_response :not_found
    get "/ko/blog/abc"
    assert_response :not_found
  end

  test "tampered locale cookie is ignored on the root redirect" do
    cookies[:locale] = "../../etc/passwd"
    get "/"
    assert_redirected_to "/ko"
  end

  test "blog pagination survives hostile page parameters" do
    Post.create!(title_ko: "글", published: true, content_ko: "<p>본문</p>")
    [ "0", "-1", "abc", "9999", "1.5", "99999999999999999999", "%00", "1; DROP TABLE posts" ].each do |value|
      get "/ko/blog", params: { page: value }
      assert_response :success, "page=#{value.inspect}"
    end
    assert_equal 1, Post.count
  end

  test "unpublished or deleted posts are never shown or listed" do
    draft = Post.create!(title_ko: "비공개 글", published: false)
    gone = Post.create!(title_ko: "삭제한 글", published: true)
    gone.discard!
    [ draft, gone ].each do |post|
      get "/ko/blog/#{post.id}"
      assert_response :not_found
    end
    get "/ko/blog"
    assert_not_includes response.body, "비공개 글"
    assert_not_includes response.body, "삭제한 글"
    get "/sitemap.xml"
    assert_not_includes response.body, "/blog/#{gone.id}"
  end

  # ---------- XSS・インジェクション ----------
  test "user-entered text is escaped everywhere it is rendered" do
    attack = %(<script>alert("x")</script>)
    SiteSetting.instance.update!(hours_ko: attack, closed_days_ko: attack, address_ko: attack, tagline_ko: attack, hero_phrase_choice: 0,
                                 business_info_ko: attack)
    cat = create_category(attack)
    create_item(cat, attack, 1000)
    Post.create!(title_ko: attack, published: true, content_ko: "<p>x</p>")
    Event.create!(title_ko: attack, message_ko: attack)

    [ "/ko", "/ko/blog", "/ko/location", "/ko/about" ].each do |path|
      get path
      assert_response :success
      assert_not_includes response.body, %(<script>alert("x")</script>), "#{path} にスクリプトがそのまま出ている"
    end
  end

  test "rich text content is sanitized" do
    post = Post.create!(title_ko: "안전", published: true,
                        content_ko: %(<p>본문</p><script>alert(1)</script><img src=x onerror=alert(1)><a href="javascript:alert(1)">링크</a>))
    get "/ko/blog/#{post.id}"
    assert_response :success
    body = response.body[/<div class="prose.*?<\/div>/m].to_s
    assert_not_includes body, "<script"
    assert_not_includes body, "onerror"
    assert_not_includes body, "javascript:"
  end

  test "structured data cannot be broken out of its script tag" do
    SiteSetting.instance.update!(address_ko: %(</script><script>alert(1)</script>), region_name_ko: %(</script>))
    get "/ko"
    ld = response.body[%r{<script type="application/ld\+json">(.*?)</script>}m, 1]
    assert ld, "JSON-LD が壊れている"
    assert JSON.parse(ld)["@type"] == "HairSalon"
    assert_not_includes response.body, "</script><script>alert(1)"
  end

  # ---------- アップロード ----------
  test "non-image, svg and oversized uploads are rejected" do
    sign_in_admin
    fake = Rack::Test::UploadedFile.new(StringIO.new("not an image at all"), "image/png", original_filename: "evil.png")
    svg = Rack::Test::UploadedFile.new(StringIO.new(%(<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>)), "image/svg+xml", original_filename: "x.svg")
    big = Rack::Test::UploadedFile.new(StringIO.new("\x89PNG\r\n\x1a\n".b + ("0".b * (6 * 1024 * 1024))), "image/png", original_filename: "big.png")

    [ fake, svg, big ].each do |file|
      patch admin_site_setting_path, params: { site_setting: { address_photo: file } }
      assert_response :unprocessable_entity, "拒否時にエラー画面（500）ではなく入力画面が再表示されるべき: #{file.original_filename}"
      assert_not SiteSetting.instance.reload.address_photo.attached?, "拒否されるべきファイルが保存された: #{file.original_filename}"
    end
  end

  test "rejected uploads re-render every admin form without crashing" do
    sign_in_admin
    fake = -> { Rack::Test::UploadedFile.new(StringIO.new("not an image"), "image/png", original_filename: "evil.png") }
    cat = create_category("커트")

    patch admin_owner_profile_path, params: { owner_profile: { photo: fake.call } }
    assert_response :unprocessable_entity
    patch admin_owner_profile_path, params: { owner_profile: { gallery_images: [ fake.call ] } }
    assert_response :unprocessable_entity
    assert_not OwnerProfile.instance.reload.photo.attached?
    patch admin_menu_category_path(cat), params: { menu_category: { name_ko: "커트", image: fake.call } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_not cat.reload.image.attached?
    assert_no_difference "Post.count" do
      post admin_posts_path, params: { post: { title_ko: "사진 위조", featured_image: fake.call } }
    end
    assert_response :unprocessable_entity
  end

  test "valid image upload is converted to webp" do
    skip "libvips が必要です" unless ImageOptimization.vips_available?

    sign_in_admin
    patch admin_site_setting_path, params: { site_setting: { address_photo: fixture_file_upload("dot.png", "image/png") } }
    assert_equal "image/webp", SiteSetting.instance.reload.address_photo.blob.content_type
  end

  # ---------- 空データ・欠損でも壊れない ----------
  test "every public page renders on an empty database" do
    MenuItem.delete_all
    MenuCategory.delete_all
    Post.delete_all
    Event.delete_all
    OwnerGreeting.delete_all
    SiteSetting.delete_all
    OwnerProfile.delete_all
    %w[ko en].each do |l|
      [ "/#{l}", "/#{l}/about", "/#{l}/blog", "/#{l}/location", "/#{l}/privacy" ].each do |path|
        get path
        assert_response :success, "#{path} が空のデータで失敗"
      end
    end
    get "/sitemap.xml"
    assert_response :success
  end

  test "pages render when optional settings are blank" do
    SiteSetting.instance.update!(phone: "", address_ko: nil, hours_ko: nil, closed_days_ko: nil, latitude: nil, longitude: nil, kakao_url: nil)
    [ "/ko", "/ko/location", "/en", "/en/location" ].each do |path|
      get path
      assert_response :success, path
    end
    get "/ko"
    assert_select "a[href^='tel:']", count: 0
  end

  # ---------- 論理削除と整合性 ----------
  test "discarding a category hides its items from the price list and restoring brings them back" do
    cat = create_category("염색")
    create_item(cat, "뿌리 염색", 30_000)
    get "/ko"
    assert_select ".price-card-title", text: /염색/
    cat.discard!
    get "/ko"
    assert_select ".price-card-title", text: /염색/, count: 0
    cat.undiscard!
    get "/ko"
    assert_select ".price-name", text: "뿌리 염색"
  end

  test "reordering ignores discarded items" do
    cat = create_category("커트")
    a = create_item(cat, "A", 1000)
    b = create_item(cat, "B", 2000)
    c = create_item(cat, "C", 3000)
    b.discard!
    a.move_down!
    assert_equal %w[C A], cat.menu_items.reload.map(&:name_ko)
    assert_equal [ c.id, a.id ], cat.menu_items.map(&:id)
  end

  test "trash rejects unknown types and unknown ids with 404" do
    sign_in_admin
    patch admin_restore_trash_path(type: "bogus", id: 1)
    assert_response :not_found
    delete admin_purge_trash_path(type: "post", id: 999_999)
    assert_response :not_found
  end

  test "trash only touches discarded records" do
    sign_in_admin
    live = Post.create!(title_ko: "살아 있는 글", published: true)
    delete admin_purge_trash_path(type: "post", id: live.id)
    assert_response :not_found
    assert Post.exists?(live.id)
  end

  # ---------- イベント期間の境界 ----------
  test "events are shown on their first and last day and hidden the day after" do
    today = Date.current
    Event.create!(title_ko: "오늘 시작", starts_on: today, ends_on: today + 3)
    Event.create!(title_ko: "오늘 종료", starts_on: today - 3, ends_on: today)
    Event.create!(title_ko: "어제 종료", starts_on: today - 3, ends_on: today - 1)
    Event.create!(title_ko: "내일 시작", starts_on: today + 1, ends_on: today + 3)
    Event.create!(title_ko: "기간 없음")
    titles = Event.active.pluck(:title_ko)
    assert_includes titles, "오늘 시작"
    assert_includes titles, "오늘 종료"
    assert_includes titles, "기간 없음"
    assert_not_includes titles, "어제 종료"
    assert_not_includes titles, "내일 시작"
  end

  test "an event cannot end before it starts" do
    event = Event.new(title_ko: "거꾸로", starts_on: Date.current + 2, ends_on: Date.current)
    assert_not event.valid?
  end

  # ---------- 価格 ----------
  test "price input is sanitized and bounded" do
    cat = create_category("커트")
    assert_equal 30_000, cat.menu_items.create!(name_ko: "A", price: "30,000원").price
    assert_equal 0, cat.menu_items.create!(name_ko: "B", price: 0).price
    assert_not cat.menu_items.new(name_ko: "C", price: -1).valid?
    assert_not cat.menu_items.new(name_ko: "D", price: "abc").valid?
    assert_not cat.menu_items.new(name_ko: "E", price: 99_999_999_999).valid?
  end

  # ---------- クリック計測 ----------
  test "click endpoint accepts only POST and clamps its inputs" do
    get "/clicks"
    assert_response :not_found
    post clicks_path, params: { kind: "call", lang: "xx", page: "a" * 500 }
    assert_response :no_content
    click = ClickEvent.last
    assert_equal "ko", click.locale
    assert_operator click.page.length, :<=, 40
    assert_no_difference "ClickEvent.count" do
      post clicks_path, params: { kind: "call'; DROP TABLE click_events;--" }
    end
  end

  # ---------- SEO ----------
  test "sitemap is well-formed xml and lists both locales" do
    get "/sitemap.xml"
    doc = Nokogiri::XML(response.body) { |c| c.strict }
    urls = doc.remove_namespaces!.xpath("//url/loc").map(&:text)
    assert(urls.any? { |u| u.end_with?("/ko") })
    assert(urls.any? { |u| u.end_with?("/en") })
  end

  test "every public page has exactly one h1, a title and a description" do
    [ "/ko", "/ko/about", "/ko/blog", "/ko/location", "/en", "/en/location" ].each do |path|
      get path
      assert_select "h1", count: 1, message: "#{path} の h1 は1つだけであるべき"
      assert_select "title", minimum: 1
      assert_select "meta[name=description][content]"
    end
  end

  # ---------- 入力の長さ ----------
  test "very long inputs are rejected rather than stored" do
    sign_in_admin
    assert_no_difference "Post.count" do
      post admin_posts_path, params: { post: { title_ko: "가" * 500 } }
    end
    assert_response :unprocessable_entity
    assert_no_difference "MenuCategory.count" do
      post admin_menu_categories_path, params: { menu_category: { name_ko: "나" * 500 } }, as: :turbo_stream
    end
  end

  test "hero phrase choice is limited to valid values" do
    sign_in_admin
    patch admin_site_setting_path, params: { site_setting: { hero_phrase_choice: "7" } }
    assert_response :unprocessable_entity
    assert_not_equal 7, SiteSetting.instance.reload.hero_phrase_choice
  end

  test "kakao url must be https" do
    sign_in_admin
    patch admin_site_setting_path, params: { site_setting: { kakao_url: "javascript:alert(1)" } }
    assert_response :unprocessable_entity
    patch admin_site_setting_path, params: { site_setting: { kakao_url: "http://insecure.example" } }
    assert_response :unprocessable_entity
  end
end
