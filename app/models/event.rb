# 初回来店特典・お知らせバナー。期間を過ぎると自動で非表示になります。
# 「クーポンコード」は使わず、「この画面を見せてください」「電話予約のときにお伝えください」と文面で案内します。
class Event < ApplicationRecord
  include Translatable
  include SoftDeletable

  translates :title, :message

  validates :title_ko, presence: true, length: { maximum: 80 }
  validate :period_is_ordered

  # 公開中・削除されていない・今日が期間内（開始日／終了日が空なら無期限）
  scope :active, lambda { |today = Date.current|
    kept.where(published: true)
        .where("starts_on IS NULL OR starts_on <= ?", today)
        .where("ends_on IS NULL OR ends_on >= ?", today)
  }

  def self.current
    active.order(:ends_on, :id).first
  end

  private

  def period_is_ordered
    return if starts_on.blank? || ends_on.blank? || starts_on <= ends_on

    errors.add(:ends_on, "은 시작일보다 같거나 늦어야 합니다")
  end
end
