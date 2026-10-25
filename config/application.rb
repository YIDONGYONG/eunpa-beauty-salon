require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Eunpa
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # 多言語: 韓国語（デフォルト）/ 英語
    config.i18n.available_locales = %i[ko en]
    config.i18n.default_locale = :ko
    config.i18n.fallbacks = [ :ko ]
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]

    config.time_zone = "Seoul"

    # メモリ1GBクラスのサーバーを考慮し、YJIT は既定でオフにします（RAILS_YJIT=true でオン）
    config.yjit = ENV["RAILS_YJIT"] == "true"

    # アップロード制限（モデルの検証で使用）
    config.x.upload_max_size = ENV.fetch("UPLOAD_MAX_MB", "5").to_i.megabytes

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
