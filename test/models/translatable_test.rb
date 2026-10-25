require "test_helper"

class TranslatableTest < ActiveSupport::TestCase
  setup do
    @category = MenuCategory.new(name_ko: "커트", name_en: "")
  end

  test "returns the value for the current locale" do
    category = MenuCategory.new(name_ko: "커트", name_en: "Haircut")
    I18n.with_locale(:en) { assert_equal "Haircut", category.name }
    I18n.with_locale(:ko) { assert_equal "커트", category.name }
  end

  test "falls back to Korean when a translation is blank or missing" do
    I18n.with_locale(:en) { assert_equal "커트", @category.name } # name_en が空
  end

  test "reports whether a translation exists" do
    I18n.with_locale(:en) { assert_not @category.name_translated? }
    I18n.with_locale(:ko) { assert @category.name_translated? }
    @category.name_en = "Haircut"
    I18n.with_locale(:en) { assert @category.name_translated? }
  end

  test "post body falls back to Korean" do
    post = Post.create!(title_ko: "제목", content_ko: "<p>한국어 본문</p>", content_en: "<p>English body</p>")
    I18n.with_locale(:en) { assert_includes post.content.to_plain_text, "English body" }
    post.content_en = ""
    I18n.with_locale(:en) { assert_includes post.content.to_plain_text, "한국어 본문" }
  end
end
