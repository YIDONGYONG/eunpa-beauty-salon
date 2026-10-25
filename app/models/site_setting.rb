# 住所・電話番号・営業時間などのサイト設定（1件のみ使用: SiteSetting.instance）
class SiteSetting < ApplicationRecord
  include Translatable
  include ImageValidation
  include ImageOptimization

  has_one_attached :map_image # 地図を読み込めないときに代わりに表示する地図の画像（NAVER 地図の画面をキャプチャして登録）
  optimize_images :map_image
  validates_image :map_image

  has_one_attached :address_photo # 「アクセス」ページの「美容室の写真」ボックスに載せる写真（外観・入口など）
  optimize_images :address_photo
  validates_image :address_photo

  translates :tagline, :region_name, :address, :hours, :closed_days, :business_info

  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :phone, length: { maximum: 30 }
  validates :hero_phrase_choice, inclusion: { in: 0..3 }
  validates :kakao_url, format: { with: %r{\Ahttps://\S+\z}, message: "은 https:// 로 시작하는 주소여야 합니다" }, allow_blank: true

  def self.instance
    first || create!(phone: "")
  end

  # tel: リンク用（数字と + だけを残す）
  def phone_href
    "tel:#{phone.to_s.gsub(/[^\d+]/, '')}"
  end

  # ホームの最初の文言。1〜3: 候補から選ぶ / 0: 管理画面で入力した tagline
  def hero_phrase
    if hero_phrase_choice.to_i.between?(1, 3)
      I18n.t("home.hero_candidates.c#{hero_phrase_choice}")
    else
      tagline.presence || I18n.t("home.hero_candidates.c3")
    end
  end

  def kakao?
    kakao_url.present?
  end

  def coordinates?
    latitude.present? && longitude.present?
  end
end
