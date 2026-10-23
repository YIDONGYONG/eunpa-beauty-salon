class CreateMenuItems < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_items do |t|
      t.references :menu_category, null: false, foreign_key: true
      t.string :name_ko, null: false
      t.string :name_en
      t.string :name_vi
      t.string :name_ja
      t.integer :price, null: false, default: 0 # 원 단위 정수
      t.boolean :price_from, null: false, default: false # "~부터" 표기
      t.text :description_ko
      t.text :description_en
      t.text :description_vi
      t.text :description_ja
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true
      t.timestamps
    end
    add_index :menu_items, [ :menu_category_id, :position ]
  end
end
