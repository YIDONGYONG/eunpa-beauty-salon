require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "requires a Korean title" do
    assert_not Post.new.valid?
  end

  test "stamps published_at when first published" do
    post = Post.create!(title_ko: "글", published: false)
    assert_nil post.published_at
    post.update!(published: true)
    assert_not_nil post.published_at
  end

  test "published scope hides drafts" do
    Post.create!(title_ko: "공개", published: true)
    Post.create!(title_ko: "비공개", published: false)
    assert_equal [ "공개" ], Post.published.map(&:title_ko)
  end

  test "pagination returns PER_PAGE posts per page, newest first" do
    (Post::PER_PAGE + 2).times { |i| Post.create!(title_ko: "글 #{i}", published: true, published_at: i.hours.ago) }
    assert_equal 2, Post.total_pages
    assert_equal Post::PER_PAGE, Post.published.latest.page(1).size
    assert_equal 2, Post.published.latest.page(2).size
    assert_equal "글 0", Post.published.latest.page(1).first.title_ko
  end

  test "rejects non-image uploads and oversized images" do
    post = Post.new(title_ko: "글")
    post.featured_image.attach(io: StringIO.new("not an image"), filename: "x.pdf", content_type: "application/pdf")
    assert_not post.valid?
    assert post.errors[:featured_image].any?
  end

  test "accepts a small png" do
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")
    post = Post.new(title_ko: "글")
    post.featured_image.attach(io: StringIO.new(png), filename: "dot.png", content_type: "image/png")
    assert post.valid?, post.errors.full_messages.to_sentence
  end
end
