require "test_helper"

class AdminContentTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "create, publish toggle, soft delete and restore a blog post" do
    assert_difference "Post.count", 1 do
      post admin_posts_path, params: { post: { title_ko: "새 글", title_en: "New post", content_ko: "<p>내용</p>", published: "0" } }
    end
    post_record = Post.last
    assert_not post_record.published?

    patch toggle_admin_post_path(post_record)
    assert post_record.reload.published?
    assert_not_nil post_record.published_at

    get "/en/blog"
    assert_select ".post-card-title", text: "New post"

    # 「削除」は論理削除: 公開側からは消えるが、ゴミ箱から戻せる
    assert_difference "Post.kept.count", -1 do
      delete admin_post_path(post_record)
    end
    assert post_record.reload.discarded?
    get "/en/blog"
    assert_select ".post-card-title", text: "New post", count: 0

    patch admin_restore_trash_path(type: "post", id: post_record.id)
    assert_not post_record.reload.discarded?
    get "/en/blog"
    assert_select ".post-card-title", text: "New post"
  end

  test "rejects a post without a Korean title" do
    post admin_posts_path, params: { post: { title_ko: "" } }
    assert_response :unprocessable_entity
  end

  test "edit site settings, shown on the location page" do
    patch admin_site_setting_path, params: { site_setting: { phone: "031-111-2222", address_ko: "경기도 어딘가 5", closed_days_en: "Closed on Sundays" } }
    assert_redirected_to edit_admin_site_setting_path
    get "/ko/location"
    assert_select "a[href=?]", "tel:0311112222"
    assert_includes response.body, "경기도 어딘가 5"
    get "/en/location"
    assert_includes response.body, "Closed on Sundays"
  end

  test "edit owner profile and greetings; a random visible greeting is shown" do
    patch admin_owner_profile_path, params: { owner_profile: { years_of_experience: 35,
      greetings_attributes: { "0" => { body_ko: "반갑습니다 원장입니다", visible: "1" },
                              "1" => { body_ko: "숨긴 인사말", visible: "0" } } } }
    get "/ko/about"
    assert_includes response.body, "반갑습니다 원장입니다" # 表示中のものは1件だけ
    assert_not_includes response.body, "숨긴 인사말"
    assert_includes response.body, "35년"
  end

  test "about page picks among several greetings" do
    profile = OwnerProfile.instance
    %w[첫째 둘째 셋째].each { |w| profile.greetings.create!(body_ko: "#{w} 인사말") }
    seen = 20.times.map do
      get "/ko/about"
      %w[첫째 둘째 셋째].find { |w| response.body.include?("#{w} 인사말") }
    end.compact.uniq
    assert_operator seen.size, :>=, 2, "ランダムなら複数のあいさつ文が出るはず"
  end

  test "events show only inside their period and hide automatically" do
    Event.create!(title_ko: "기간 중 이벤트", starts_on: Date.current - 1, ends_on: Date.current + 1)
    Event.create!(title_ko: "지난 이벤트", starts_on: Date.current - 10, ends_on: Date.current - 2)
    Event.create!(title_ko: "숨긴 이벤트", published: false)
    get "/ko"
    assert_includes response.body, "기간 중 이벤트"
    assert_not_includes response.body, "지난 이벤트"
    assert_not_includes response.body, "숨긴 이벤트"
  end

  test "click counter stores only a count (kind, locale, page)" do
    assert_difference "ClickEvent.count", 1 do
      post clicks_path, params: { kind: "call", lang: "ko", page: "home" }
    end
    assert_response :no_content
    assert_no_difference "ClickEvent.count" do
      post clicks_path, params: { kind: "bogus" }
    end
  end

  test "owner photo is hidden by default and shown only after the admin turns it on" do
    png = fixture_file_upload("dot.png", "image/png")
    patch admin_owner_profile_path, params: { owner_profile: { photo: png } }
    assert OwnerProfile.instance.photo.attached?
    assert_not OwnerProfile.instance.show_photo_on_home?
    get "/ko"
    assert_select "img.hero-owner-photo", count: 0
    get "/ko/about"
    assert_select "img.owner-photo", count: 0

    patch admin_owner_profile_path, params: { owner_profile: { show_photo_on_home: "1" } }
    get "/ko"
    assert_select "img.hero-owner-photo"
    get "/ko/about"
    assert_select "img.owner-photo"
  end

  test "change password requires the current one" do
    patch admin_password_path, params: { current_password: "wrong", password: "brand-new-pass1", password_confirmation: "brand-new-pass1" }
    assert_response :unprocessable_entity
    patch admin_password_path, params: { current_password: ADMIN_PASSWORD, password: "brand-new-pass1", password_confirmation: "brand-new-pass1" }
    assert_redirected_to admin_root_path
    assert AdminUser.first.authenticate("brand-new-pass1")
  end

  test "new admin pages render (events, trash, site settings, owner profile)" do
    event = Event.create!(title_ko: "휴지통 이벤트")
    event.discard!
    [ admin_events_path, new_admin_event_path, admin_trash_index_path, edit_admin_site_setting_path,
      edit_admin_owner_profile_path, admin_root_path ].each do |path|
      get path
      assert_response :success, "#{path} should render"
    end
    assert_includes response.body, "휴지통"
    get admin_trash_index_path
    assert_includes response.body, "휴지통 이벤트"
  end

  test "event admin: create, hide and soft delete" do
    assert_difference "Event.count", 1 do
      post admin_events_path, params: { event: { title_ko: "새 이벤트", starts_on: Date.current, ends_on: Date.current + 7, published: "1" } }
    end
    event = Event.last
    patch toggle_admin_event_path(event)
    assert_not event.reload.published?
    assert_difference "Event.kept.count", -1 do
      delete admin_event_path(event)
    end
    patch admin_restore_trash_path(type: "event", id: event.id)
    assert_not event.reload.discarded?
  end

  test "hero phrase can be chosen from three candidates" do
    patch admin_site_setting_path, params: { site_setting: { hero_phrase_choice: "1" } }
    get "/ko"
    assert_includes response.body, "한결같은 손길"
    patch admin_site_setting_path, params: { site_setting: { hero_phrase_choice: "0", tagline_ko: "직접 쓴 문구입니다" } }
    get "/ko"
    assert_includes response.body, "직접 쓴 문구입니다"
  end

  test "salon photo box shows a placeholder, then the uploaded photo on the location page" do
    get "/ko/location"
    # 写真を登録する前でも空の枠が表示される
    png = fixture_file_upload("dot.png", "image/png")
    patch admin_site_setting_path, params: { site_setting: { address_photo: png } }
    assert SiteSetting.instance.address_photo.attached?
    get "/ko/location"
    assert_select "img.address-photo"
    assert_select "a[href*='copy']", count: 0
    assert_not_includes response.body, "주차 안내"
    delete address_photo_admin_site_setting_path
    assert_not SiteSetting.instance.reload.address_photo.attached?
  end

  test "uploaded map image is the fallback under the map" do
    get "/ko/location"
    assert_select ".map-fallback img.map-image", count: 0
    png = fixture_file_upload("dot.png", "image/png")
    patch admin_site_setting_path, params: { site_setting: { map_image: png } }
    assert SiteSetting.instance.map_image.attached?
    get "/ko/location"
    assert_select ".map-fallback img.map-image"
    delete map_image_admin_site_setting_path
    assert_not SiteSetting.instance.reload.map_image.attached?
  end
end
