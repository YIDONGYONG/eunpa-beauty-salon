# カカオトーク関連の機能を廃止（カカオの情報は扱わない方針）
class RemoveKakaoFromSiteSettings < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM click_events WHERE kind = 'kakao'"
    remove_column :site_settings, :kakao_url
  end

  def down
    add_column :site_settings, :kakao_url, :string
  end
end
