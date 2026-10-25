# 論理削除: 削除したデータを管理画面の「ゴミ箱」から戻せるようにする（ADR 0006）
class AddDiscardedAtForSoftDelete < ActiveRecord::Migration[8.1]
  def change
    %i[menu_categories menu_items posts].each do |table|
      add_column table, :discarded_at, :datetime
      add_index table, :discarded_at
    end
  end
end
