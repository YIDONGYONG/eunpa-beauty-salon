# 恩波美容室のシードデータ
#
# ⚠️ すべての値は「仮の例」です。実際の価格／住所／電話番号／座標は管理画面（/admin）で修正してください。
# ⚠️ 英語・ベトナム語・日本語の文言は翻訳の「草稿」です。公開前に専門家による校閲が必要です。
#
# 何度実行しても安全です（すでにある項目には触れません）。

# ---------------------------------------------------------------- 管理者アカウント
email = ENV["ADMIN_EMAIL"].presence
password = ENV["ADMIN_PASSWORD"].presence

if email.nil? || password.nil?
  if Rails.env.production?
    puts "[seed] ADMIN_EMAIL / ADMIN_PASSWORD 가 없어 관리자 계정을 만들지 않았습니다."
  else
    email = "admin@example.com"
    password = "change-me-please"
    puts "[seed] 개발용 임시 관리자 계정을 사용합니다: #{email} / #{password}  (.env 에서 바꾸세요)"
  end
end

if email && password && AdminUser.none?
  AdminUser.create!(email: email, password: password)
  puts "[seed] 관리자 계정 생성: #{email}"
end

# ---------------------------------------------------------------- メニュー / 価格
menu = [
  {
    names: { ko: "커트", en: "Haircut", vi: "Cắt tóc", ja: "カット" },
    items: [
      { names: { ko: "여성 커트", en: "Women's haircut", vi: "Cắt tóc nữ", ja: "レディースカット" }, price: 15_000 },
      { names: { ko: "남성 커트", en: "Men's haircut", vi: "Cắt tóc nam", ja: "メンズカット" }, price: 12_000 },
      { names: { ko: "어린이 커트", en: "Children's haircut", vi: "Cắt tóc trẻ em", ja: "キッズカット" }, price: 9_000 }
    ]
  },
  {
    names: { ko: "파마", en: "Perm", vi: "Uốn tóc", ja: "パーマ" },
    items: [
      { names: { ko: "일반 파마", en: "Regular perm", vi: "Uốn tóc thông thường", ja: "通常パーマ" }, price: 40_000, from: true },
      { names: { ko: "셋팅 파마", en: "Setting perm", vi: "Uốn tóc tạo kiểu (setting)", ja: "セットパーマ" }, price: 55_000, from: true },
      { names: { ko: "뿌리 볼륨 파마", en: "Root volume perm", vi: "Uốn phồng chân tóc", ja: "根元ボリュームパーマ" }, price: 30_000, from: true,
        desc: { ko: "정수리와 뿌리 부분만 볼륨을 살려 드립니다.", en: "Adds volume to the crown and roots only.",
                vi: "Chỉ tạo độ phồng cho đỉnh đầu và chân tóc.", ja: "頭頂部と根元だけにボリュームを出します。" } }
    ]
  }
]

menu.each do |cat|
  category = MenuCategory.find_or_initialize_by(name_ko: cat[:names][:ko])
  if category.new_record?
    category.assign_attributes(cat[:names].transform_keys { |l| :"name_#{l}" })
    category.save!
  end

  cat[:items].each do |it|
    next if category.menu_items.exists?(name_ko: it[:names][:ko])

    item = category.menu_items.new(price: it[:price], price_from: it[:from] || false)
    it[:names].each { |l, v| item[:"name_#{l}"] = v }
    (it[:desc] || {}).each { |l, v| item[:"description_#{l}"] = v }
    item.save!
  end
end

# ---------------------------------------------------------------- 院長紹介
profile = OwnerProfile.instance
if profile.greeting_ko.blank?
  profile.update!(
    years_of_experience: 30,
    name_ko: "원장님", name_en: "The Owner", name_vi: "Chủ tiệm", name_ja: "店主",
    headline_ko: "30년 넘게 한자리에서 이웃의 머리를 가꿔 왔습니다.",
    headline_en: "For over 30 years, I have cared for my neighbors' hair in the same place.",
    headline_vi: "Hơn 30 năm qua, tôi luôn chăm sóc mái tóc cho bà con hàng xóm tại chính nơi này.",
    headline_ja: "30年以上、同じ場所でご近所の皆さまの髪を整えてまいりました。",
    greeting_ko: "안녕하세요, 은파미용실입니다.\n오랜 시간 찾아 주시는 단골 손님들 덕분에 지금까지 올 수 있었습니다.\n머리 모양은 물론 두피와 머릿결 고민까지 편하게 말씀해 주세요. 한 분 한 분 정성껏 해 드리겠습니다.\n(임시 문구입니다. 관리자 화면에서 수정해 주세요.)",
    greeting_en: "Hello, and welcome to Eunpa Hair Salon.\nWe have come this far thanks to our many loyal customers who have visited us over the years.\nPlease feel free to tell us about your hairstyle, scalp or hair concerns. We will take care of each guest with sincerity.\n(Placeholder text. Please edit in the admin page.)",
    greeting_vi: "Xin chào, đây là tiệm tóc Eunpa.\nNhờ những vị khách thân quen đã ghé thăm suốt nhiều năm, chúng tôi mới có được ngày hôm nay.\nXin hãy thoải mái chia sẻ về kiểu tóc, da đầu hay chất tóc của quý khách. Chúng tôi sẽ tận tâm chăm sóc từng người.\n(Nội dung tạm thời. Vui lòng chỉnh sửa trong trang quản trị.)",
    greeting_ja: "こんにちは、ウンパ美容室です。\n長年お越しくださる常連のお客様のおかげで、今日まで続けてくることができました。\nヘアスタイルはもちろん、頭皮や髪のお悩みもお気軽にご相談ください。お一人おひとり心を込めて対応いたします。\n（仮の文章です。管理画面で修正してください。）",
    career_ko: "미용 경력 30년 이상\n커트와 파마를 전문으로 합니다.\n(임시 문구입니다. 관리자 화면에서 수정해 주세요.)",
    career_en: "Over 30 years in hairdressing\nSpecializing in cuts and perms.\n(Placeholder text. Please edit in the admin page.)",
    career_vi: "Hơn 30 năm kinh nghiệm làm tóc\nChuyên cắt và uốn tóc.\n(Nội dung tạm thời. Vui lòng chỉnh sửa trong trang quản trị.)",
    career_ja: "美容歴30年以上\nカットとパーマを専門としています。\n（仮の文章です。管理画面で修正してください。）"
  )
end

# ---------------------------------------------------------------- サイト設定
setting = SiteSetting.instance
if setting.address_ko.blank?
  setting.update!(
    phone: "054-535-6353",           # NAVER プレイスの掲載情報
    latitude: 36.4126275, longitude: 128.1626006, # NAVER 地図の店舗座標
    tagline_ko: "30년 정성으로 머리를 가꿔 드립니다",
    tagline_en: "Caring for your hair with over 30 years of experience",
    tagline_vi: "Chăm sóc mái tóc của bạn bằng hơn 30 năm kinh nghiệm",
    tagline_ja: "30年の経験で心を込めて髪を整えます",
    address_ko: "경북 상주시 왕산로 160",
    address_en: "160 Wangsan-ro, Sangju-si, Gyeongsangbuk-do",
    address_vi: "160 Wangsan-ro, thành phố Sangju, tỉnh Gyeongsangbuk-do",
    address_ja: "慶尚北道 尚州市 王山路160",
    hours_ko: "화~토 오전 9:30 ~ 오후 7:00\n일요일 오전 9:30 ~ 오후 5:00",
    hours_en: "Tue–Sat 9:30 AM – 7:00 PM\nSunday 9:30 AM – 5:00 PM",
    hours_vi: "Thứ Ba – Thứ Bảy: 9:30 – 19:00\nChủ Nhật: 9:30 – 17:00",
    hours_ja: "火〜土 午前9:30 〜 午後7:00\n日曜日 午前9:30 〜 午後5:00",
    closed_days_ko: "매주 월요일 (공휴일은 미리 안내해 드립니다)",
    closed_days_en: "Every Monday (holiday closures will be announced in advance)",
    closed_days_vi: "Thứ Hai hằng tuần (ngày nghỉ lễ sẽ được thông báo trước)",
    closed_days_ja: "毎週月曜日（祝日の休業は事前にご案内します）",
    parking_ko: "건물 뒤편 공용 주차장을 이용하실 수 있습니다. (임시 안내)",
    parking_en: "You may use the shared parking lot behind the building. (Placeholder)",
    parking_vi: "Quý khách có thể sử dụng bãi đỗ xe chung phía sau tòa nhà. (Tạm thời)",
    parking_ja: "建物の裏にある共用駐車場をご利用いただけます。（仮の案内）",
    entrance_ko: "큰길에서 약국 옆 골목으로 들어오시면 분홍색 간판이 보입니다. 1층이라 계단이 없습니다. (임시 안내)",
    entrance_en: "Turn into the alley next to the pharmacy and look for the pink sign. We are on the ground floor, so there are no stairs. (Placeholder)",
    entrance_vi: "Từ đường lớn, rẽ vào con hẻm cạnh hiệu thuốc và tìm biển hiệu màu hồng. Tiệm ở tầng trệt nên không có cầu thang. (Tạm thời)",
    entrance_ja: "大通りから薬局の横の路地に入ると、ピンク色の看板が見えます。1階なので階段はありません。（仮の案内）",
    business_info_ko: "상호: 은파미용실 · 대표: (입력 예정) · 사업자등록번호: (입력 예정)",
    business_info_en: "Business name: Eunpa Hair Salon · Representative: (to be added) · Business registration no.: (to be added)",
    business_info_vi: "Tên cơ sở: Tiệm tóc Eunpa · Đại diện: (sẽ bổ sung) · Mã số đăng ký kinh doanh: (sẽ bổ sung)",
    business_info_ja: "屋号: ウンパ美容室 · 代表者: (追記予定) · 事業者登録番号: (追記予定)"
  )
end

# ---------------------------------------------------------------- ブログのサンプル記事
posts = [
  {
    titles: { ko: "환절기 모발 관리, 이렇게 해 보세요", en: "Hair care for changing seasons", vi: "Chăm sóc tóc khi giao mùa", ja: "季節の変わり目のヘアケア" },
    bodies: {
      ko: "<p>계절이 바뀌면 머릿결이 푸석해지고 두피가 건조해지기 쉽습니다.</p><ul><li>샴푸는 미지근한 물로, 두피를 손끝으로 부드럽게 문질러 주세요.</li><li>트리트먼트는 모발 끝 위주로 바르고 충분히 헹궈 주세요.</li><li>젖은 채로 자지 말고 드라이어는 멀리서 시원한 바람으로 말려 주세요.</li></ul>",
      en: "<p>When the seasons change, hair easily becomes dry and the scalp loses moisture.</p><ul><li>Wash with lukewarm water and gently massage the scalp with your fingertips.</li><li>Apply conditioner mainly to the ends and rinse well.</li><li>Do not sleep with wet hair; dry it with a cool setting held at a distance.</li></ul>",
      vi: "<p>Khi giao mùa, tóc dễ bị khô xơ và da đầu thiếu ẩm.</p><ul><li>Gội bằng nước ấm và massage nhẹ da đầu bằng đầu ngón tay.</li><li>Chỉ thoa dầu xả chủ yếu ở phần đuôi tóc và xả sạch.</li><li>Không đi ngủ khi tóc còn ướt; sấy tóc bằng gió mát ở khoảng cách xa.</li></ul>",
      ja: "<p>季節の変わり目は髪がパサつき、頭皮も乾燥しやすくなります。</p><ul><li>シャンプーはぬるま湯で、指の腹で頭皮をやさしく洗いましょう。</li><li>トリートメントは毛先を中心につけ、しっかりすすぎましょう。</li><li>濡れたまま寝ず、ドライヤーは離して冷風で乾かしましょう。</li></ul>"
    }
  },
  {
    titles: { ko: "파마 후 첫 일주일, 이것만은 꼭 지켜 주세요", en: "The first week after a perm: what to remember", vi: "Tuần đầu sau khi uốn tóc: những điều cần nhớ", ja: "パーマ後の最初の一週間、守っていただきたいこと" },
    bodies: {
      ko: "<p>파마 후 이틀 동안은 머리를 감지 않는 것이 좋습니다.</p><ul><li>머리를 꽉 묶거나 핀으로 고정하지 마세요.</li><li>빗은 살이 굵고 성긴 것을 사용하세요.</li><li>샴푸 후에는 수건으로 눌러 물기를 제거하고 자연스럽게 말려 주세요.</li></ul>",
      en: "<p>It is best not to wash your hair for two days after a perm.</p><ul><li>Avoid tying your hair tightly or fixing it with pins.</li><li>Use a wide-toothed comb.</li><li>After shampooing, press out water with a towel and let it dry naturally.</li></ul>",
      vi: "<p>Sau khi uốn, tốt nhất không nên gội đầu trong hai ngày.</p><ul><li>Không buộc tóc chặt hoặc cố định bằng kẹp.</li><li>Dùng lược thưa, răng to.</li><li>Sau khi gội, dùng khăn thấm nước và để tóc khô tự nhiên.</li></ul>",
      ja: "<p>パーマ後の2日間は、髪を洗わないことをおすすめします。</p><ul><li>きつく結んだり、ピンで留めたりしないでください。</li><li>目の粗いコームを使いましょう。</li><li>シャンプー後はタオルで水気を押さえ、自然乾燥させましょう。</li></ul>"
    }
  },
  {
    titles: { ko: "나에게 맞는 커트 길이 고르는 법", en: "How to choose the right haircut length", vi: "Cách chọn độ dài tóc phù hợp", ja: "自分に合うカットの長さの選び方" },
    bodies: {
      ko: "<p>나이가 들면 머리숱과 모질이 달라져 길이에 따라 인상이 크게 바뀝니다.</p><p>얼굴이 갸름해 보이길 원하시면 턱선 아래로 가볍게, 볼륨을 살리고 싶으시면 귀 아래 길이로 층을 내는 것이 좋습니다. 방문하시면 얼굴형에 맞춰 편하게 상담해 드립니다.</p>",
      en: "<p>As we age, hair volume and texture change, so length can greatly alter your impression.</p><p>For a slimmer look, a light cut just below the jawline works well; for more volume, layers around ear length are a good choice. Visit us and we will happily advise you based on your face shape.</p>",
      vi: "<p>Khi lớn tuổi, độ dày và chất tóc thay đổi nên độ dài tóc ảnh hưởng nhiều đến ấn tượng chung.</p><p>Nếu muốn khuôn mặt thon gọn, hãy cắt nhẹ ngay dưới đường quai hàm; nếu muốn tóc phồng hơn, nên cắt tầng ngang tai. Hãy ghé tiệm để được tư vấn theo khuôn mặt của bạn.</p>",
      ja: "<p>年齢とともに髪の量や質が変わるため、長さによって印象が大きく変わります。</p><p>顔をすっきり見せたい場合はあご先より少し下で軽く、ボリュームを出したい場合は耳下の長さでレイヤーを入れるのがおすすめです。ご来店の際、顔の形に合わせてご相談に応じます。</p>"
    }
  }
]

posts.each_with_index do |data, index|
  next if Post.exists?(title_ko: data[:titles][:ko])

  post = Post.new(published: true, published_at: Time.current - index.days)
  data[:titles].each { |l, v| post[:"title_#{l}"] = v }
  data[:bodies].each { |l, v| post.public_send(:"content_#{l}=", v) }
  post.save!
end

puts "[seed] 완료: 분류 #{MenuCategory.count}, 시술 #{MenuItem.count}, 글 #{Post.count}"
