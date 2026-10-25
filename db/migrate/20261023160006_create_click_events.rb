# 「電話」「道案内」ボタンのクリック数。個人を特定する情報は保存しません（ADR 0007）。
class CreateClickEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :click_events do |t|
      t.string :kind, null: false   # call / directions / kakao
      t.string :locale, null: false, default: "ko"
      t.string :page
      t.datetime :created_at, null: false
    end
    add_index :click_events, %i[kind created_at]
  end
end
