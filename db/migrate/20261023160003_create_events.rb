# 初回来店特典・お知らせバナー。期間を過ぎると自動で非表示になります。
class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title_ko, null: false
      t.string :title_en
      t.text :message_ko
      t.text :message_en
      t.date :starts_on
      t.date :ends_on
      t.boolean :published, null: false, default: true
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :events, %i[published starts_on ends_on]
  end
end
