# 院長紹介（1件のみ使用: OwnerProfile.instance）
class OwnerProfile < ApplicationRecord
  include Translatable
  include ImageValidation
  include ImageOptimization

  translates :name, :headline, :greeting, :career

  has_one_attached :photo
  has_many_attached :gallery_images

  validates :years_of_experience, numericality: { only_integer: true, greater_than: 0 }
  optimize_images :photo, :gallery_images
  validates_image :photo, :gallery_images

  def self.instance
    first || create!(name_ko: "원장님", years_of_experience: 30)
  end
end
