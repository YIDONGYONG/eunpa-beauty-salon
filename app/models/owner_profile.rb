# 院長紹介（1件のみ使用: OwnerProfile.instance）
class OwnerProfile < ApplicationRecord
  include Translatable
  include ImageValidation
  include ImageOptimization

  translates :name, :headline, :career

  has_many :greetings, -> { ordered }, class_name: "OwnerGreeting", dependent: :destroy
  accepts_nested_attributes_for :greetings, reject_if: ->(attrs) { attrs[:body_ko].blank? && attrs[:body_en].blank? && attrs[:body_ja].blank? }

  has_one_attached :photo
  has_many_attached :gallery_images

  validates :career_start_year, numericality: { only_integer: true, greater_than_or_equal_to: 1930 }
  validate :career_start_year_not_in_future
  optimize_images :photo, :gallery_images
  validates_image :photo, :gallery_images

  # 表示中のあいさつ文からランダムに1つ（なければ nil）
  def random_greeting
    greetings.select(&:visible?).sample
  end

  # 経歴の年数。開始年から毎年自動で増える（開始年が入っていなければ 1 年）
  def years_of_experience
    [ Date.current.year - career_start_year.to_i, 1 ].max
  end

  def self.instance
    first || create!(name_ko: "원장님", career_start_year: Date.current.year - 30)
  end

  # 画面の文言に差し込む経歴年数（ロケールの %{years}）
  def self.current_years
    instance.years_of_experience
  end

  private

  def career_start_year_not_in_future
    errors.add(:career_start_year, "은 올해보다 클 수 없습니다") if career_start_year.to_i > Date.current.year
  end
end
