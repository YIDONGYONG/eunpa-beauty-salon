require_relative "boot"

require "rails/all"

# Gemfile に書かれた gem（:test・:development・:production に限定したものを含む）を読み込みます。
Bundler.require(*Rails.groups)

module Eunpa
  class Application < Rails::Application
    # 最初に生成された Rails のバージョンの既定値を読み込みます。
    config.load_defaults 8.1

    # `lib` の下に .rb ファイルを含まないサブディレクトリや、再読み込み・先読みの対象にしたくないものは、
    # `ignore` リストに追加してください（例: `templates`、`generators`、`middleware`）。
    config.autoload_lib(ignore: %w[assets tasks])

    # 多言語: 韓国語（デフォルト）/ 英語 / 日本語
    config.i18n.available_locales = %i[ko en ja]
    config.i18n.default_locale = :ko
    config.i18n.fallbacks = [ :ko ]
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]

    config.time_zone = "Seoul"

    # メモリ1GBクラスのサーバーを考慮し、YJIT は既定でオフにします（RAILS_YJIT=true でオン）
    config.yjit = ENV["RAILS_YJIT"] == "true"

    # アップロード制限（モデルの検証で使用）
    config.x.upload_max_size = ENV.fetch("UPLOAD_MAX_MB", "5").to_i.megabytes

    # アプリ・エンジン・railtie の設定をここに書きます。
    #
    # これらの設定は、後から読み込まれる config/environments の各ファイルで、環境ごとに上書きできます。
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
