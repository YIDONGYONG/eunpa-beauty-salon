# 일본어(ja) 지원 추가: 번역 입력용 _ja 컬럼 (ADR 0003 개정)
# 블로그 본문(Action Text)은 별도 테이블이라 마이그레이션이 필요 없습니다.
class AddJapaneseColumns < ActiveRecord::Migration[8.1]
  COLUMNS = {
    events: { title_ja: :string, message_ja: :text },
    menu_categories: { name_ja: :string },
    menu_items: { name_ja: :string, description_ja: :text },
    owner_greetings: { body_ja: :text },
    owner_profiles: { name_ja: :text, headline_ja: :text, career_ja: :text },
    posts: { title_ja: :string },
    site_settings: { tagline_ja: :text, address_ja: :text, hours_ja: :text, closed_days_ja: :text,
                     parking_ja: :text, entrance_ja: :text, business_info_ja: :text, region_name_ja: :string }
  }.freeze

  def change
    COLUMNS.each do |table, columns|
      columns.each { |name, type| add_column table, name, type }
    end
  end
end
