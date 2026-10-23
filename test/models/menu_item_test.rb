require "test_helper"

class MenuItemTest < ActiveSupport::TestCase
  setup { @category = create_category }

  test "requires a Korean name" do
    item = @category.menu_items.new(price: 1000)
    assert_not item.valid?
    assert item.errors[:name_ko].any?
  end

  test "price keeps digits only so 30,000원 becomes 30000" do
    item = create_item(@category, "일반 파마", "30,000원")
    assert_equal 30_000, item.price
  end

  test "price must be a non-negative integer" do
    item = @category.menu_items.new(name_ko: "테스트", price: -1)
    assert_not item.valid?
  end

  test "new items are appended in order" do
    a = create_item(@category, "A", 1000)
    b = create_item(@category, "B", 2000)
    c = create_item(@category, "C", 3000)
    assert_equal %w[A B C], @category.menu_items.reload.map(&:name_ko)
    assert a.position < b.position && b.position < c.position
  end

  test "move_up! and move_down! swap neighbours" do
    a = create_item(@category, "A", 1000)
    b = create_item(@category, "B", 2000)
    c = create_item(@category, "C", 3000)

    c.move_up!
    assert_equal %w[A C B], @category.menu_items.reload.map(&:name_ko)
    a.move_down!
    assert_equal %w[C A B], @category.menu_items.reload.map(&:name_ko)
    c.move_up! # すでに一番上: 変化なし
    assert_equal %w[C A B], @category.menu_items.reload.map(&:name_ko)
  end

  test "positions are scoped per category" do
    other = create_category("파마")
    create_item(@category, "A", 1000)
    x = create_item(other, "X", 5000)
    x.move_up!
    assert_equal %w[X], other.menu_items.reload.map(&:name_ko)
  end

  test "price list only contains visible categories and items" do
    create_item(@category, "보임", 1000)
    create_item(@category, "숨김", 2000, visible: false)
    hidden = create_category("숨긴 분류", visible: false)
    create_item(hidden, "아무거나", 3000)

    list = MenuCategory.for_price_list
    assert_equal [ "커트" ], list.map { |c, _| c.name_ko }
    assert_equal [ "보임" ], list.first.last.map(&:name_ko)
  end

  test "destroying a category removes its items" do
    create_item(@category, "A", 1000)
    assert_difference "MenuItem.count", -1 do
      @category.destroy
    end
  end
end
