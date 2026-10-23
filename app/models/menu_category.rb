class MenuCategory < ApplicationRecord
  include Translatable
  include Positionable

  translates :name

  has_many :menu_items, -> { ordered }, dependent: :destroy

  validates :name_ko, presence: true, length: { maximum: 40 }

  scope :visible, -> { where(visible: true) }

  # ホーム画面の料金表用: 表示中のカテゴリと施術のみ
  def self.for_price_list
    visible.ordered.includes(:menu_items).map do |category|
      [ category, category.menu_items.select(&:visible?) ]
    end.reject { |_, items| items.empty? }
  end
end
