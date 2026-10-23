require "test_helper"

class AdminContentTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "create, publish toggle and delete a blog post" do
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

    assert_difference "Post.count", -1 do
      delete admin_post_path(post_record)
    end
  end

  test "rejects a post without a Korean title" do
    post admin_posts_path, params: { post: { title_ko: "" } }
    assert_response :unprocessable_entity
  end

  test "edit site settings, shown on the location page" do
    patch admin_site_setting_path, params: { site_setting: { phone: "031-111-2222", address_ko: "경기도 어딘가 5", parking_en: "Free parking" } }
    assert_redirected_to edit_admin_site_setting_path
    get "/ko/location"
    assert_select "a[href=?]", "tel:0311112222"
    assert_includes response.body, "경기도 어딘가 5"
    get "/en/location"
    assert_includes response.body, "Free parking"
  end

  test "edit owner profile greeting" do
    patch admin_owner_profile_path, params: { owner_profile: { greeting_ko: "반갑습니다 원장입니다", years_of_experience: 35 } }
    get "/ko/about"
    assert_includes response.body, "반갑습니다 원장입니다"
    assert_includes response.body, "35년"
  end

  test "owner photo can be uploaded and replaces the placeholder" do
    png = fixture_file_upload("dot.png", "image/png")
    patch admin_owner_profile_path, params: { owner_profile: { photo: png } }
    assert OwnerProfile.instance.photo.attached?
    get "/ko/about"
    assert_select "img.owner-photo[src*='rails/active_storage']"
  end

  test "change password requires the current one" do
    patch admin_password_path, params: { current_password: "wrong", password: "brand-new-pass1", password_confirmation: "brand-new-pass1" }
    assert_response :unprocessable_entity
    patch admin_password_path, params: { current_password: ADMIN_PASSWORD, password: "brand-new-pass1", password_confirmation: "brand-new-pass1" }
    assert_redirected_to admin_root_path
    assert AdminUser.first.authenticate("brand-new-pass1")
  end
end
