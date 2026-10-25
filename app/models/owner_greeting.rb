# 院長紹介ページのあいさつ文。複数登録しておき、表示のたびにランダムで1つ選びます（ADR 0005）
class OwnerGreeting < ApplicationRecord
  include Translatable
  include Positionable

  translates :body
  positioned_within :owner_profile_id

  belongs_to :owner_profile

  validates :body_ko, presence: true, length: { maximum: 1000 }

  scope :visible, -> { where(visible: true) }
end
