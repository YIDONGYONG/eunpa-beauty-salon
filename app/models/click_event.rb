# 「電話」「道案内」などのボタンのクリック数を数えます。
# Cookie・IP・端末情報は保存しません（個人を特定できない件数だけ。ADR 0007）。
class ClickEvent < ApplicationRecord
  KINDS = %w[call directions kakao].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :locale, inclusion: { in: %w[ko en] }

  # { "call" => 12, "directions" => 5 } 形式で、直近 days 日の件数
  def self.counts_since(days)
    where(created_at: days.days.ago..).group(:kind).count
  end
end
