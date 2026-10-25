class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :phone
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      # 4言語で入力するテキスト設定（のちに ko / en の2言語へ縮小。ADR 0003）
      %w[tagline address hours closed_days parking entrance business_info].each do |col|
        %w[ko en vi ja].each { |l| t.text :"#{col}_#{l}" }
      end
      t.timestamps
    end
  end
end
