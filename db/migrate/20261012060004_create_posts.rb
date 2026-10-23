class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title_ko, null: false
      t.string :title_en
      t.string :title_vi
      t.string :title_ja
      t.boolean :published, null: false, default: false
      t.datetime :published_at
      t.timestamps
    end
    add_index :posts, [ :published, :published_at ]
  end
end
