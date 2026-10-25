# 地域名（SEO用）、カカオトーク、ホームの最初の文言の選択
class AddFieldsToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :region_name_ko, :string
    add_column :site_settings, :region_name_en, :string
    add_column :site_settings, :kakao_url, :string
    # 1〜3: 候補から選ぶ / 0: tagline（自由入力）を使う
    add_column :site_settings, :hero_phrase_choice, :integer, null: false, default: 3
    # 検索エンジン向けの営業時間（schema.org の形式。例: "Mo-Sa 09:00-19:00"）
    add_column :site_settings, :schema_hours, :string, default: "Mo-Sa 09:00-19:00"
  end
end
