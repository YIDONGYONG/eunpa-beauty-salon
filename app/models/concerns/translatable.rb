# 4言語（ko/en/vi/ja）で入力するDBコンテンツを扱う共通モジュールです。
#
# カラムは `name_ko`、`name_en`、`name_vi`、`name_ja` のように言語ごとに分かれており、
# `translates :name` を宣言すると、現在の言語（I18n.locale）の値を返す `name` メソッドが
# 定義されます。現在の言語の値が空なら韓国語の値にフォールバックします。
module Translatable
  extend ActiveSupport::Concern

  LOCALES = %i[ko en vi ja].freeze

  class_methods do
    def translates(*attrs)
      attrs.each do |attr|
        define_method(attr) { translated(attr) }
        define_method(:"#{attr}_translated?") { translated?(attr) }
      end
    end
  end

  # name_ko / name_en ... のうち locale の値を返す（なければ韓国語）
  def translated(attr, locale = I18n.locale)
    value = self[:"#{attr}_#{locale}"]
    value = self[:"#{attr}_#{I18n.default_locale}"] if value.blank?
    value
  end

  # 現在の言語の翻訳が入力されているか？
  def translated?(attr, locale = I18n.locale)
    self[:"#{attr}_#{locale}"].present?
  end
end
