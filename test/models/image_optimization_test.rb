require "test_helper"

class ImageOptimizationTest < ActiveSupport::TestCase
  test "non-upload values pass through untouched" do
    assert_equal "x", ImageOptimization.optimize("x")
    assert_nil ImageOptimization.optimize(nil)
  end

  test "large photos are shrunk to the max edge (needs libvips)" do
    skip "libvips가 없는 환경입니다 (Docker에서 실행하세요)" unless ImageOptimization.vips_available?

    big = Tempfile.new([ "big", ".jpg" ])
    Vips::Image.black(3200, 2400).add(120).cast(:uchar).write_to_file(big.path)
    upload = ActionDispatch::Http::UploadedFile.new(tempfile: big, filename: "big.jpg", type: "image/jpeg")

    profile = OwnerProfile.new(years_of_experience: 30)
    profile.photo = upload
    profile.save!

    image = Vips::Image.new_from_buffer(profile.photo.download, "")
    assert_operator [ image.width, image.height ].max, :<=, ImageOptimization::MAX_EDGE
  end
end
