# 院長紹介のあいさつ文を複数持ち、表示のたびにランダムで1つ選ぶ（ADR 0005）。
# 既存の owner_profiles.greeting_ko / greeting_en は1件目として移します。
class CreateOwnerGreetings < ActiveRecord::Migration[8.1]
  def up
    create_table :owner_greetings do |t|
      t.references :owner_profile, null: false, foreign_key: true
      t.text :body_ko, null: false
      t.text :body_en
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true
      t.timestamps
    end

    execute <<~SQL
      INSERT INTO owner_greetings (owner_profile_id, body_ko, body_en, position, visible, created_at, updated_at)
      SELECT id, greeting_ko, greeting_en, 0, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM owner_profiles
      WHERE greeting_ko IS NOT NULL AND greeting_ko != ''
    SQL

    remove_column :owner_profiles, :greeting_ko
    remove_column :owner_profiles, :greeting_en
  end

  def down
    add_column :owner_profiles, :greeting_ko, :text
    add_column :owner_profiles, :greeting_en, :text
    drop_table :owner_greetings
  end
end
