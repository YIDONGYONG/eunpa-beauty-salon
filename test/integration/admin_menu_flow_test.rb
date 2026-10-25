require "test_helper"

class AdminMenuFlowTest < ActionDispatch::IntegrationTest
  setup do
    @category = create_category("커트")
    @item = create_item(@category, "여성 커트", 15_000)
  end

  test "admin pages require login" do
    get admin_menu_items_path
    assert_redirected_to admin_login_path
    patch admin_menu_item_path(@item), params: { menu_item: { price: "1" } }
    assert_redirected_to admin_login_path
    assert_equal 15_000, @item.reload.price
  end

  test "login with wrong password fails, correct password succeeds" do
    create_admin
    post admin_session_path, params: { email: "owner@example.com", password: "nope" }
    assert_response :unprocessable_entity

    post admin_session_path, params: { email: "owner@example.com", password: ADMIN_PASSWORD }
    assert_redirected_to admin_root_path
    follow_redirect!
    assert_response :success
  end

  test "logout ends the session" do
    sign_in_admin
    delete admin_session_path
    get admin_root_path
    assert_redirected_to admin_login_path
  end

  test "inline edit updates name and price with a turbo stream" do
    sign_in_admin
    patch admin_menu_item_path(@item),
          params: { menu_item: { name_ko: "여성 컷", price: "18,000", price_from: "1" } },
          as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "저장되었습니다"
    @item.reload
    assert_equal "여성 컷", @item.name_ko
    assert_equal 18_000, @item.price
    assert @item.price_from?
  end

  test "invalid inline edit returns 422 and keeps old data" do
    sign_in_admin
    patch admin_menu_item_path(@item), params: { menu_item: { name_ko: "" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_equal "여성 커트", @item.reload.name_ko
  end

  test "can save translations of an item" do
    sign_in_admin
    patch admin_menu_item_path(@item),
          params: { menu_item: { name_en: "Women's cut" } },
          as: :turbo_stream
    @item.reload
    assert_equal "Women's cut", @item.name_en
  end

  test "add an item" do
    sign_in_admin
    assert_difference "MenuItem.count", 1 do
      post admin_menu_items_path,
           params: { menu_item: { menu_category_id: @category.id, name_ko: "남성 커트", price: "12000" } },
           as: :turbo_stream
    end
    assert_response :success
    assert_equal 12_000, MenuItem.find_by(name_ko: "남성 커트").price
  end

  test "move, toggle and delete an item" do
    other = create_item(@category, "남성 커트", 12_000)
    sign_in_admin

    patch move_down_admin_menu_item_path(@item), as: :turbo_stream
    assert_equal [ "남성 커트", "여성 커트" ], @category.menu_items.reload.map(&:name_ko)

    patch toggle_admin_menu_item_path(@item), as: :turbo_stream
    assert_not @item.reload.visible?

    assert_difference "MenuItem.kept.count", -1 do
      delete admin_menu_item_path(other), as: :turbo_stream
    end
    # 論理削除（ゴミ箱から復元できる）
  end

  test "category create, rename and reorder" do
    sign_in_admin
    assert_difference "MenuCategory.count", 1 do
      post admin_menu_categories_path, params: { menu_category: { name_ko: "염색" } }, as: :turbo_stream
    end
    dye = MenuCategory.find_by(name_ko: "염색")
    patch admin_menu_category_path(dye), params: { menu_category: { name_ko: "염색·탈색", name_en: "Dye" } }, as: :turbo_stream
    assert_equal "염색·탈색", dye.reload.name_ko

    patch move_up_admin_menu_category_path(dye), as: :turbo_stream
    assert_equal dye, MenuCategory.ordered.first
  end

  test "price changes show up on the public home page immediately" do
    sign_in_admin
    patch admin_menu_item_path(@item), params: { menu_item: { price: "21000" } }, as: :turbo_stream
    get "/ko"
    assert_select ".price-value", text: "21,000원"
  end

  test "menu management page renders" do
    sign_in_admin
    get admin_menu_items_path
    assert_response :success
    assert_select "input[name='menu_item[name_ko]'][value='여성 커트']"
  end

  test "category photo shows at the top of the price card and can be removed" do
    sign_in_admin
    png = fixture_file_upload("dot.png", "image/png")
    patch admin_menu_category_path(@category), params: { menu_category: { name_ko: @category.name_ko, image: png } }, as: :turbo_stream
    assert @category.reload.image.attached?
    get "/ko"
    assert_select ".price-card img.price-card-icon"
    patch admin_menu_category_path(@category), params: { menu_category: { name_ko: @category.name_ko, remove_image: "1" } }, as: :turbo_stream
    perform_enqueued_jobs { }
    get "/ko"
    assert_select ".price-card img.price-card-icon", count: 0 unless @category.reload.image.attached?
  end
end
