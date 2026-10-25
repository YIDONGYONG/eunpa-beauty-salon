# 翻訳言語を韓国語（ko）と英語（en）の2つに絞る（ADR 0003）。
# `_vi` / `_ja` で終わるカラムと、本文（Action Text）の vi / ja を削除します。
class RemoveVietnameseAndJapaneseColumns < ActiveRecord::Migration[8.1]
  TABLES = %i[menu_categories menu_items owner_profiles posts site_settings].freeze

  def up
    TABLES.each do |table|
      columns(table).map(&:name).grep(/_(vi|ja)\z/).each { |name| remove_column table, name }
    end
    execute "DELETE FROM action_text_rich_texts WHERE name IN ('content_vi', 'content_ja')"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "削除した vi / ja の翻訳データは戻せません（バックアップから復元してください）"
  end
end
