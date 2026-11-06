# 経歴を「年数」ではなく「開始年」で持つ（表示の年数は毎年自動で増える）
class ReplaceYearsWithCareerStartYear < ActiveRecord::Migration[8.1]
  def up
    add_column :owner_profiles, :career_start_year, :integer
    execute "UPDATE owner_profiles SET career_start_year = CAST(strftime('%Y', 'now') AS INTEGER) - years_of_experience"
    remove_column :owner_profiles, :years_of_experience
  end

  def down
    add_column :owner_profiles, :years_of_experience, :integer, null: false, default: 30
    execute "UPDATE owner_profiles SET years_of_experience = CAST(strftime('%Y', 'now') AS INTEGER) - career_start_year WHERE career_start_year IS NOT NULL"
    remove_column :owner_profiles, :career_start_year
  end
end
