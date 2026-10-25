# 院長の写真を公開画面（ホーム上部・紹介ページ）に出すかどうか。既定は「出さない」。
# 写真をアップロードしただけでは表示されず、院長が管理画面で「表示」にしたときだけ表示される。
class AddShowPhotoOnHomeToOwnerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :owner_profiles, :show_photo_on_home, :boolean, null: false, default: false
  end
end
