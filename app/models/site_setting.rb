# 住所・電話番号・営業時間などのサイト設定（1件のみ使用: SiteSetting.instance）
class SiteSetting < ApplicationRecord
  include Translatable
  include ImageValidation
  include ImageOptimization

  has_one_attached :hero_photo
  optimize_images :hero_photo
  validates_image :hero_photo

  translates :tagline, :address, :hours, :closed_days, :parking, :entrance, :business_info

  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :phone, length: { maximum: 30 }

  def self.instance
    first || create!(phone: "")
  end

  # tel: リンク用（数字と + だけを残す）
  def phone_href
    "tel:#{phone.to_s.gsub(/[^\d+]/, '')}"
  end

  def coordinates?
    latitude.present? && longitude.present?
  end
end
