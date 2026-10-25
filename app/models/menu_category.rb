class MenuCategory < ApplicationRecord
  include Translatable
  include Positionable
  include SoftDeletable
  include ImageValidation
  include ImageOptimization

  translates :name

  has_one_attached :image # 料金カードの見出しの横に出る小さな画像（例: カット・パーマのアイコン）
  optimize_images :image
  validates_image :image

  has_many :menu_items, -> { kept.ordered }, dependent: :destroy

  validates :name_ko, presence: true, length: { maximum: 40 }

  scope :visible, -> { where(visible: true) }

  # ホーム画面の料金表用: 表示中のカテゴリと施術のみ
  def self.for_price_list
    kept.visible.ordered.includes(:menu_items).map do |category|
      [ category, category.menu_items.select(&:visible?) ]
    end.reject { |_, items| items.empty? }
  end
end
