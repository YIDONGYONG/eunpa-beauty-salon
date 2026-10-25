require "test_helper"

# ハーネス（ガードレール）: 翻訳漏れと、公開画面へのハードコード文言を自動で検出します。
class I18nConsistencyTest < ActiveSupport::TestCase
  LOCALES = %w[ko en].freeze

  def flatten(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [ prefix, key ].compact.join(".")
      value.is_a?(Hash) ? flatten(value, path) : [ path ]
    end
  end

  def keys_for(locale)
    data = YAML.load_file(Rails.root.join("config/locales/#{locale}.yml"))
    flatten(data.fetch(locale)).sort
  end

  test "en defines exactly the same keys as ko" do
    base = keys_for("ko")
    (LOCALES - [ "ko" ]).each do |locale|
      keys = keys_for(locale)
      assert_equal [], base - keys, "#{locale}.yml 에 빠진 키"
      assert_equal [], keys - base, "#{locale}.yml 에만 있는 키(ko.yml에도 추가하세요)"
    end
  end

  test "interpolation variables match across languages" do
    ko = YAML.load_file(Rails.root.join("config/locales/ko.yml"))["ko"]
    (LOCALES - [ "ko" ]).each do |locale|
      other = YAML.load_file(Rails.root.join("config/locales/#{locale}.yml"))[locale]
      flatten(ko).each do |key|
        a = key.split(".").inject(ko) { |h, k| h[k] }
        b = key.split(".").inject(other) { |h, k| h[k] }
        next unless a.is_a?(String) && b.is_a?(String)

        assert_equal a.scan(/%\{(\w+)\}/).flatten.sort, b.scan(/%\{(\w+)\}/).flatten.sort,
                     "#{locale}.#{key} 의 %{변수}가 ko 와 다릅니다"
      end
    end
  end

  test "public views contain no hard-coded Korean text (use config/locales)" do
    files = Dir[Rails.root.join("app/views/**/*.erb")].reject do |f|
      f.include?("/views/admin/") || f.include?("admin") && f.include?("/layouts/") ||
        f.include?("/views/error_mailer/") # 管理者（開発者）宛のエラー通知メールは公開画面ではない
    end
    offenders = files.flat_map do |file|
      File.readlines(file).each_with_index.filter_map do |line, i|
        next if line.include?("<%#")
        "#{file.sub(Rails.root.to_s + '/', '')}:#{i + 1}" if line.match?(/[가-힣]/)
      end
    end
    assert_equal [], offenders, "공개 화면에 한글이 직접 들어 있습니다. t('...') 로 바꾸세요."
  end
end
