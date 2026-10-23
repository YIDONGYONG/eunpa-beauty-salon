module ApplicationHelper
  LOCALE_CODES = { ko: "KO", en: "EN", vi: "VI", ja: "JA" }.freeze

  def base_url
    ENV["APP_BASE_URL"].presence || request.base_url
  end

  # 価格表記: 「30,000원」/「30,000원부터」（言語別の形式は locale ファイル）
  def format_price(item)
    amount = number_with_delimiter(item.price, delimiter: ",")
    t(item.price_from? ? "price.from" : "price.won", amount: amount)
  end

  def post_date(time)
    time&.strftime(t("date_format"))
  end

  # ページのタイトル／説明の指定（レイアウトの title、meta タグで使用）
  def page_title(title = nil)
    return content_for(:title) if title.nil?
    content_for(:title, title)
  end

  def page_description(text = nil)
    return content_for(:description) if text.nil?
    content_for(:description, text)
  end

  # 変換可能な環境（libvips）ならリサイズ済み画像を、そうでなければ原本を使います。
  def variants_available?
    return @@variants_available if defined?(@@variants_available)

    @@variants_available =
      begin
        require "vips"
        true
      rescue LoadError
        false
      end
  end

  def salon_image_tag(attachment, width:, height: nil, **options)
    source =
      if variants_available? && attachment.variable?
        attachment.variant(resize_to_limit: [ width, height || width ])
      else
        attachment
      end
    image_tag source, loading: "lazy", decoding: "async", **options
  end

  # 現在の言語の翻訳がなく韓国語を表示する場合の案内文
  def translation_fallback_notice(translated)
    return if I18n.locale == I18n.default_locale || translated

    tag.p t("common.translation_fallback"), class: "notice notice-info"
  end

  # 改行を含むテキストを安全に段落として表示
  def multiline(text)
    simple_format(h(text.to_s), {}, sanitize: false)
  end

  # ---- NAVER 地図 / 道案内 ----
  def naver_client_id
    ENV["NAVER_MAP_CLIENT_ID"].to_s
  end

  def naver_navi_app_url(setting, name)
    return nil unless setting.coordinates?

    query = { dlat: setting.latitude.to_f, dlng: setting.longitude.to_f, dname: name,
              appname: ENV.fetch("NAVER_APP_NAME", "kr.eunpa.salon") }
    "nmap://navigation?#{query.to_query}"
  end

  def naver_web_url(setting)
    address = setting.address_ko.presence || t("site.name")
    "https://map.naver.com/p/search/#{ERB::Util.url_encode(address)}"
  end
end
