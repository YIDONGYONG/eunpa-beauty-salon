class MenuItem < ApplicationRecord
  include Translatable
  include Positionable
  include SoftDeletable

  translates :name, :description
  positioned_within :menu_category_id

  belongs_to :menu_category

  validates :name_ko, presence: true, length: { maximum: 60 }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                    less_than_or_equal_to: 10_000_000 }

  scope :visible, -> { where(visible: true) }

  # 管理者が「30,000」や「30000ウォン」のように入力しても、数字だけを残します。
  def price=(value)
    super(value.is_a?(String) ? value.gsub(/[^\d]/, "").presence : value)
  end
end
