# 院長紹介（1件のみ使用: OwnerProfile.instance）
class OwnerProfile < ApplicationRecord
  include Translatable
  include ImageValidation
  include ImageOptimization

  translates :name, :headline, :career

  has_many :greetings, -> { ordered }, class_name: "OwnerGreeting", dependent: :destroy
  accepts_nested_attributes_for :greetings, reject_if: ->(attrs) { attrs[:body_ko].blank? && attrs[:body_en].blank? }

  has_one_attached :photo
  has_many_attached :gallery_images

  validates :years_of_experience, numericality: { only_integer: true, greater_than: 0 }
  optimize_images :photo, :gallery_images
  validates_image :photo, :gallery_images

  # 表示中のあいさつ文からランダムに1つ（なければ nil）
  def random_greeting
    greetings.select(&:visible?).sample
  end

  def self.instance
    first || create!(name_ko: "원장님", years_of_experience: 30)
  end
end
