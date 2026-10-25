# 恩波美容室のシードデータ
#
# ⚠️ すべての値は「仮の例」です。実際の価格／住所／電話番号／座標は管理画面（/admin）で修正してください。
# ⚠️ 英語の文言は翻訳の「草稿」です。公開前にネイティブまたは専門家による校閲が必要です。
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
    names: { ko: "커트", en: "Haircut" },
    items: [
      { names: { ko: "여성 커트", en: "Women's haircut" }, price: 15_000 },
      { names: { ko: "남성 커트", en: "Men's haircut" }, price: 12_000 },
      { names: { ko: "어린이 커트", en: "Children's haircut" }, price: 9_000 }
    ]
  },
  {
    names: { ko: "파마", en: "Perm" },
    items: [
      { names: { ko: "일반 파마", en: "Regular perm" }, price: 40_000, from: true },
      { names: { ko: "셋팅 파마", en: "Setting perm" }, price: 55_000, from: true },
      { names: { ko: "뿌리 볼륨 파마", en: "Root volume perm" }, price: 30_000, from: true,
        desc: { ko: "정수리와 뿌리 부분만 볼륨을 살려 드립니다.", en: "Adds volume to the crown and roots only." } }
    ]
  }
]

menu.each do |cat|
  category = MenuCategory.find_or_initialize_by(name_ko: cat[:names][:ko])
  if category.new_record?
    category.assign_attributes(cat[:names].transform_keys { |l| :"name_#{l}" })
    category.save!
  end

  # 料金カードの画像（db/seed_images/category-*.webp。なければ何もしない）
  image = Rails.root.join("db/seed_images", { "커트" => "category-cut.webp", "파마" => "category-perm.webp" }.fetch(category.name_ko, "-"))
  if image.exist? && !category.image.attached?
    category.image.attach(io: File.open(image), filename: image.basename.to_s, content_type: "image/webp")
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
if profile.headline_ko.blank?
  profile.update!(
    years_of_experience: 30,
    name_ko: "원장님", name_en: "The Owner",
    headline_ko: "30년 넘게 한자리에서 이웃의 머리를 가꿔 왔습니다.",
    headline_en: "For over 30 years, I have cared for my neighbors' hair in the same place.",
    career_ko: "미용 경력 30년 이상\n커트와 파마를 전문으로 합니다.\n(임시 문구입니다. 관리자 화면에서 수정해 주세요.)",
    career_en: "Over 30 years in hairdressing\nSpecializing in cuts and perms.\n(Placeholder text. Please edit in the admin page.)"
  )
end

# あいさつ文は3つ。表示のたびにランダムで1つが選ばれます（仮の文章）
if profile.greetings.none?
  [
    [ "안녕하세요, 은파미용실입니다.\n오랜 시간 찾아 주시는 단골 손님들 덕분에 지금까지 올 수 있었습니다.\n머리 모양은 물론 두피와 머릿결 고민까지 편하게 말씀해 주세요. 한 분 한 분 정성껏 해 드리겠습니다.\n(임시 문구입니다. 관리자 화면에서 수정해 주세요.)",
      "Hello, and welcome to Eunpa Hair Salon.\nWe have come this far thanks to our many loyal customers who have visited us over the years.\nPlease feel free to tell us about your hairstyle, scalp or hair concerns. We will take care of each guest with sincerity.\n(Placeholder text. Please edit in the admin page.)" ],
    [ "30년 동안 같은 자리에서 머리를 만져 왔습니다.\n처음 오시는 분도, 오래된 단골님도 내 집처럼 편안하게 앉으세요.\n어떤 머리가 어울릴지 천천히 여쭤보고, 꼼꼼하게 해 드리겠습니다.\n(임시 문구입니다. 관리자 화면에서 수정해 주세요.)",
      "For over 30 years I have been doing hair in this same place.\nWhether it is your first visit or you have been with us for years, please sit back and relax as if you were at home.\nWe will take our time to learn what suits you, and do it with care.\n(Placeholder text. Please edit in the admin page.)" ],
    [ "머리가 마음에 드시면 하루가 달라집니다.\n커트와 파마, 한 가지만 잘하자는 마음으로 30년을 해 왔습니다.\n불편한 점이 있으면 언제든 편하게 말씀해 주세요.\n(임시 문구입니다. 관리자 화면에서 수정해 주세요.)",
      "When you like your hair, your whole day feels different.\nFor 30 years I have focused on doing cuts and perms well.\nIf anything feels uncomfortable, please tell us anytime.\n(Placeholder text. Please edit in the admin page.)" ]
  ].each_with_index do |(ko, en), index|
    profile.greetings.create!(body_ko: ko, body_en: en, position: index)
  end
end

# 院長の写真（db/seed_images/owner.jpg があれば一度だけ登録）
photo = Rails.root.join("db/seed_images/owner.jpg")
if !profile.photo.attached? && photo.exist?
  profile.photo.attach(io: File.open(photo), filename: "owner.jpg", content_type: "image/jpeg")
end

# ---------------------------------------------------------------- サイト設定
setting = SiteSetting.instance
if setting.address_ko.blank?
  setting.update!(
    phone: "054-535-6353",           # NAVER プレイスの掲載情報
    region_name_ko: "상주", region_name_en: "Sangju",
    hero_phrase_choice: 3,           # 1〜3: 候補（config/locales の home.hero_candidates）/ 0: tagline を使う
    latitude: 36.4126275, longitude: 128.1626006, # NAVER 地図の店舗座標
    tagline_ko: "30년 경력 원장이 직접,\n어울리는 머리를 꼼꼼하게 해드립니다.",
    tagline_en: "A 30-year veteran owner personally styles hair to suit you, with care.",
    address_ko: "경북 상주시 왕산로 160",
    address_en: "160 Wangsan-ro, Sangju-si, Gyeongsangbuk-do",
    hours_ko: "월~토 오전 9시 ~ 오후 7시",
    hours_en: "Mon–Sat 9:00 AM – 7:00 PM",
    closed_days_ko: "일요일 휴무",
    closed_days_en: "Closed on Sundays",
    business_info_ko: "상호: 은파미용실 · 대표: (입력 예정) · 사업자등록번호: (입력 예정)",
    business_info_en: "Business name: Eunpa Hair Salon · Representative: (to be added) · Business registration no.: (to be added)",
  )
end

# ---------------------------------------------------------------- ブログのサンプル記事
posts = [
  {
    image: "post-hair.webp",
    titles: { ko: "50대 여성 추천 헤어 6가지 — 컷 3 · 파마 3", en: "6 Recommended Hairstyles for Women in Their 50s — 3 Cuts & 3 Perms" },
    bodies: {
      ko: "<p>50대가 되면 머리숱과 모질이 달라져서, 같은 스타일도 느낌이 달라집니다. 얼굴형과 머릿결에 맞춰 고르기 좋은 스타일 6가지를 간단히 소개합니다.</p><h2>컷</h2><ul><li><strong>숏컷</strong> — 세련되고 시원한 스타일. 목선이 깔끔해 보이고 관리가 쉽습니다.</li><li><strong>레이어드컷</strong> — 자연스러운 볼륨과 가벼움. 숱이 줄어 힘이 없을 때 좋습니다.</li><li><strong>보브컷</strong> — 단정하고 우아한 이미지. 턱선 주변을 부드럽게 감싸 줍니다.</li></ul><h2>파마</h2><ul><li><strong>S컬펌</strong> — 부드럽고 여성스러운 컬. 얼굴선을 자연스럽게 감싸 줍니다.</li><li><strong>볼륨펌</strong> — 풍성하고 생기 있는 스타일. 정수리가 납작할 때 추천합니다.</li><li><strong>내추럴펌</strong> — 자연스러운 웨이브의 멋. 손질이 편합니다.</li></ul><p>어떤 스타일이 어울리는지는 얼굴형, 머리숱, 모질에 따라 달라집니다. 편하게 전화나 방문으로 상담해 주세요. (위 사진은 스타일을 보여 드리기 위한 예시 일러스트이며, 실제 고객 사진이 아닙니다.)</p>",
      en: "<p>In your 50s, hair volume and texture change, so the same style can look different. Here are six styles that are easy to choose by face shape and hair type.</p><h2>Cuts</h2><ul><li><strong>Short cut</strong> — A refined, fresh look. Shows off a clean neckline and is easy to maintain.</li><li><strong>Layered cut</strong> — Natural volume and lightness. Good when hair has become thinner or limp.</li><li><strong>Bob cut</strong> — A neat, elegant image that softly frames the jawline.</li></ul><h2>Perms</h2><ul><li><strong>S-curl perm</strong> — Soft, feminine curls that gently frame the face.</li><li><strong>Volume perm</strong> — Full, lively style. Recommended when the crown looks flat.</li><li><strong>Natural perm</strong> — A charm of natural waves, easy to style.</li></ul><p>What suits you depends on your face shape, hair amount and texture. Please call or visit us for a consultation. (The photo above is an illustration to show the styles, not photos of real customers.)</p>"
    }
  },
  {
    titles: { ko: "환절기 모발 관리, 이렇게 해 보세요", en: "Hair care for changing seasons" },
    bodies: {
      ko: "<p>계절이 바뀌면 머릿결이 푸석해지고 두피가 건조해지기 쉽습니다.</p><ul><li>샴푸는 미지근한 물로, 두피를 손끝으로 부드럽게 문질러 주세요.</li><li>트리트먼트는 모발 끝 위주로 바르고 충분히 헹궈 주세요.</li><li>젖은 채로 자지 말고 드라이어는 멀리서 시원한 바람으로 말려 주세요.</li></ul>",
      en: "<p>When the seasons change, hair easily becomes dry and the scalp loses moisture.</p><ul><li>Wash with lukewarm water and gently massage the scalp with your fingertips.</li><li>Apply conditioner mainly to the ends and rinse well.</li><li>Do not sleep with wet hair; dry it with a cool setting held at a distance.</li></ul>"
    }
  },
  {
    titles: { ko: "파마 후 첫 일주일, 이것만은 꼭 지켜 주세요", en: "The first week after a perm: what to remember" },
    bodies: {
      ko: "<p>파마 후 이틀 동안은 머리를 감지 않는 것이 좋습니다.</p><ul><li>머리를 꽉 묶거나 핀으로 고정하지 마세요.</li><li>빗은 살이 굵고 성긴 것을 사용하세요.</li><li>샴푸 후에는 수건으로 눌러 물기를 제거하고 자연스럽게 말려 주세요.</li></ul>",
      en: "<p>It is best not to wash your hair for two days after a perm.</p><ul><li>Avoid tying your hair tightly or fixing it with pins.</li><li>Use a wide-toothed comb.</li><li>After shampooing, press out water with a towel and let it dry naturally.</li></ul>"
    }
  },
  {
    titles: { ko: "나에게 맞는 커트 길이 고르는 법", en: "How to choose the right haircut length" },
    bodies: {
      ko: "<p>나이가 들면 머리숱과 모질이 달라져 길이에 따라 인상이 크게 바뀝니다.</p><p>얼굴이 갸름해 보이길 원하시면 턱선 아래로 가볍게, 볼륨을 살리고 싶으시면 귀 아래 길이로 층을 내는 것이 좋습니다. 방문하시면 얼굴형에 맞춰 편하게 상담해 드립니다.</p>",
      en: "<p>As we age, hair volume and texture change, so length can greatly alter your impression.</p><p>For a slimmer look, a light cut just below the jawline works well; for more volume, layers around ear length are a good choice. Visit us and we will happily advise you based on your face shape.</p>"
    }
  },
  {
    image: "post-perm.jpg",
    titles: { ko: "파마, 얼마나 오래 가나요? 오래 유지하는 법", en: "How long does a perm last? Tips to keep it longer" },
    bodies: {
      ko: "<p>\"파마가 금방 풀려요\"는 손님들께서 가장 자주 하시는 질문입니다. 모질과 머리 길이, 평소 관리에 따라 차이가 있지만, 보통 3~4개월 정도면 모양이 서서히 풀리기 시작합니다.</p><p>조금만 신경 쓰시면 더 오래, 예쁘게 유지하실 수 있습니다.</p><ul><li>파마 후 이틀 동안은 머리를 감지 않고, 꽉 묶거나 핀으로 누르지 마세요.</li><li>샴푸 후에는 수건으로 눌러 물기만 없애고, 말릴 때 손으로 컬을 살살 말아 올려 주세요.</li><li>빗은 살이 굵고 성긴 것을 쓰시고, 젖은 머리를 세게 빗지 마세요.</li><li>머리끝이 건조하면 컬이 쉽게 풀리고 푸석해집니다. 트리트먼트는 머리끝 위주로 발라 주세요.</li></ul><p>모양이 처졌거나 힘이 없어졌다고 느껴지시면 편하게 전화 주세요. 머릿결 상태를 보고 알맞은 방법을 안내해 드립니다.</p>",
      en: "<p>\"My perm falls out too quickly\" is one of the questions we hear most. It depends on hair type, length, and daily care, but a perm usually starts to loosen after about 3 to 4 months.</p><p>With a little care, you can keep it looking good for longer.</p><ul><li>For two days after a perm, do not wash your hair, and avoid tight ties or pins.</li><li>After shampooing, press out water with a towel and gently scrunch the curls upward as you dry.</li><li>Use a wide-toothed comb and do not comb wet hair roughly.</li><li>Dry ends make curls fall out and look frizzy. Apply conditioner mainly to the ends.</li></ul><p>If your curls have dropped or feel limp, please call us. We will check your hair and advise you.</p>"
    }
  },
  {
    image: "post-color.jpg",
    titles: { ko: "새치 염색, 얼마나 자주 해야 하나요?", en: "How often should I color my gray hair?" },
    bodies: {
      ko: "<p>머리카락은 한 달에 1cm 정도 자라기 때문에, 보통 4~6주가 지나면 뿌리 쪽 새치가 눈에 띄기 시작합니다. 그래서 많은 분들이 한 달 반 정도 간격으로 오십니다.</p><ul><li>새로 자란 뿌리 부분만 염색하면 머릿결 부담이 줄어듭니다. 전체 염색은 가끔만 하셔도 됩니다.</li><li>염색 직후 하루 이틀은 샴푸를 미루고, 뜨거운 물은 피하면 색이 더 오래 갑니다.</li><li>염색 후에는 트리트먼트로 머릿결 수분을 챙겨 주세요.</li><li>두피가 예민하시거나 염색약으로 따가웠던 적이 있다면, 시술 전에 꼭 말씀해 주세요.</li></ul><p>원하시는 밝기와 머릿결 상태에 맞춰 주기를 같이 정해 드립니다. 편하게 문의해 주세요.</p>",
      en: "<p>Hair grows about 1 cm a month, so gray roots usually start to show after 4 to 6 weeks. Many customers visit about every six weeks.</p><ul><li>Coloring only the new growth at the roots is gentler on your hair. A full color is only needed once in a while.</li><li>For a day or two after coloring, put off shampooing and avoid hot water to keep the color longer.</li><li>Use conditioner after coloring to keep your hair moisturized.</li><li>If you have a sensitive scalp or have had stinging from hair dye, please tell us before your service.</li></ul><p>We will help you decide the interval based on your preferred shade and your hair condition. Feel free to ask.</p>"
    }
  },
  {
    image: "post-volume.jpg",
    titles: { ko: "머리숱이 줄고 힘이 없어요, 어떻게 하면 좋을까요?", en: "My hair is thinner and limp. What can I do?" },
    bodies: {
      ko: "<p>나이가 들면 머리카락이 가늘어지고 숱이 줄어 보이는 것은 누구에게나 오는 자연스러운 변화입니다. 헤어스타일만 바꿔도 풍성해 보일 수 있습니다.</p><ul><li>머리 길이는 너무 길지 않게, 층을 가볍게 내면 볼륨이 살아납니다.</li><li>뿌리 쪽에 힘을 주는 볼륨 파마를 하면 정수리가 납작해 보이는 것을 줄일 수 있습니다.</li><li>샴푸할 때는 손끝으로 두피를 부드럽게 마사지해 주세요.</li><li>무거운 트리트먼트는 뿌리에 바르지 말고 머리끝에만 사용하세요.</li></ul><p>다만 짧은 기간에 머리카락이 빠지는 양이 눈에 띄게 늘었다면 피부과 상담도 함께 권해 드립니다. 미용실에서는 지금 머릿결에 맞는 스타일을 편하게 상담해 드리겠습니다.</p>",
      en: "<p>As we age, hair becomes finer and looks thinner. This is a natural change that happens to everyone. A new hairstyle alone can make your hair look fuller.</p><ul><li>Avoid keeping your hair too long, and light layers will bring back volume.</li><li>A root-volume perm can reduce a flat look at the crown.</li><li>When shampooing, gently massage your scalp with your fingertips.</li><li>Do not apply heavy conditioner to the roots; use it on the ends only.</li></ul><p>However, if you notice a sudden increase in hair loss over a short period, we also recommend consulting a dermatologist. At the salon, we will happily advise on a style that suits your hair now.</p>"
    }
  }
]

posts.each_with_index do |data, index|
  next if Post.exists?(title_ko: data[:titles][:ko])

  post = Post.new(published: true, published_at: Time.current - index.days)
  data[:titles].each { |l, v| post[:"title_#{l}"] = v }
  data[:bodies].each { |l, v| post.public_send(:"content_#{l}=", v) }
  image = Rails.root.join("db/seed_images", data[:image].to_s)
  post.featured_image.attach(io: File.open(image), filename: data[:image], content_type: Marcel::MimeType.for(Pathname.new(image))) if data[:image] && File.exist?(image)
  post.save!
end

# ---------------------------------------------------------------- お知らせ・初回特典（仮）
if Event.none?
  Event.create!(
    title_ko: "첫 방문 감사 혜택", title_en: "Thank-you offer for first-time guests",
    message_ko: "처음 오시는 분은 전화 예약 시 \"홈페이지 보고 전화했어요\"라고 말씀해 주세요. (임시 문구입니다)",
    message_en: "First-time guests: please tell us you saw our website when you call to book. (Placeholder text)",
    starts_on: Date.current, ends_on: Date.current + 60, published: true
  )
end

puts "[seed] 완료: 분류 #{MenuCategory.count}, 시술 #{MenuItem.count}, 글 #{Post.count}"
