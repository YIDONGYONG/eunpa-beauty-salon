class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :phone
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      # 4개 언어로 입력하는 텍스트 설정
      %w[tagline address hours closed_days parking entrance business_info].each do |col|
        %w[ko en vi ja].each { |l| t.text :"#{col}_#{l}" }
      end
      t.timestamps
    end
  end
end
