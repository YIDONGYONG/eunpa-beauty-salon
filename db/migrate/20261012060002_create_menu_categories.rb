class CreateMenuCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_categories do |t|
      t.string :name_ko, null: false
      t.string :name_en
      t.string :name_vi
      t.string :name_ja
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true
      t.timestamps
    end
    add_index :menu_categories, :position
  end
end
