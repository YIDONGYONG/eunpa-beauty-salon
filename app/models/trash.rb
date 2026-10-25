# 管理画面の「ゴミ箱」: 論理削除されたデータをまとめて扱う（モデルではなく検索用の小さなクラス）
class Trash
  TYPES = {
    "menu_item" => [ MenuItem, "시술" ],
    "menu_category" => [ MenuCategory, "분류" ],
    "post" => [ Post, "블로그 글" ],
    "event" => [ Event, "이벤트" ]
  }.freeze

  Entry = Struct.new(:type, :type_label, :record, :title, :discarded_at)

  def self.entries
    TYPES.flat_map do |type, (klass, label)|
      klass.discarded.map { |r| Entry.new(type, label, r, r.try(:title_ko) || r.try(:name_ko), r.discarded_at) }
    end.sort_by(&:discarded_at).reverse
  end

  def self.count
    TYPES.values.sum { |klass, _| klass.discarded.count }
  end

  def self.find(type, id)
    klass = TYPES.fetch(type.to_s) { raise ActiveRecord::RecordNotFound, "unknown type" }.first
    klass.discarded.find(id)
  end
end
