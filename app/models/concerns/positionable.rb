# 管理者が上／下ボタンで変更する「表示順」を扱うモジュールです。
# `positioned_within :menu_category_id` のように、同じグループの範囲カラムを指定できます。
module Positionable
  extend ActiveSupport::Concern

  included do
    before_create :assign_last_position
    scope :ordered, -> { order(:position, :id) }
  end

  class_methods do
    def positioned_within(*columns)
      @position_scope_columns = columns
    end

    def position_scope_columns
      @position_scope_columns || []
    end
  end

  def siblings
    scope = self.class.ordered
    self.class.position_scope_columns.each { |col| scope = scope.where(col => self[col]) }
    scope
  end

  def move_up!   = move!(-1)
  def move_down! = move!(1)

  private

  def assign_last_position
    self.position = (siblings.maximum(:position) || -1) + 1 if position.to_i.zero?
  end

  # 同じグループの順序を 0..n-1 に振り直しながら、隣と入れ替えます。
  def move!(delta)
    transaction do
      list = siblings.to_a
      index = list.index(self)
      target = index + delta
      next if index.nil? || target.negative? || target >= list.size

      list[index], list[target] = list[target], list[index]
      list.each_with_index do |record, i|
        record.update_column(:position, i) unless record.position == i
      end
      reload
    end
  end
end
