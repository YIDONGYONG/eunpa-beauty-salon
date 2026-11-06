# NAVER スマートプレイスの予約ページ（空ならボタンは表示されない）
class AddNaverBookingUrlToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :naver_booking_url, :string
  end
end
