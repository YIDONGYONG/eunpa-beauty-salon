# 論理削除: 「削除」しても行は消さず discarded_at に時刻を入れて隠します。
# 管理画面の「ゴミ箱」から復元（undiscard!）や完全削除（destroy）ができます（ADR 0006）。
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :kept, -> { where(discarded_at: nil) }
    scope :discarded, -> { where.not(discarded_at: nil) }
  end

  def discard!   = update_columns(discarded_at: Time.current)
  def undiscard! = update_columns(discarded_at: nil)
  def discarded? = discarded_at.present?
end
