# test 環境は、アプリのテスト実行専用です。それ以外で使うことはありません。
# テスト用データベースは「作業用の置き場」で、テストの実行のたびに消去・再作成されます。
# このデータベースに入っているデータには頼らないでください。

Rails.application.configure do
  # ここでの設定は config/application.rb の設定より優先されます。

  # テスト中はファイルを監視しないので、再読み込みは不要です。
  config.enable_reloading = false

  # 先読み（eager load）はアプリ全体を読み込みます。手元で1つのテストだけ動かすときは通常不要で、
  # テストが遅くなることもあります。ただし、デプロイ前に先読みが正しく動くことを確かめるため、
  # CI（継続的インテグレーション）では有効にすることを勧めます。
  config.eager_load = ENV["CI"].present?

  # テスト用に、cache-control を付けた公開ファイルの配信を設定します（性能のため）。
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }

  # 詳細なエラーレポートを表示します。
  config.consider_all_requests_local = true
  config.cache_store = :null_store

  # rescue できる例外はエラーページを表示し、それ以外の例外はそのまま発生させます。
  config.action_dispatch.show_exceptions = :rescuable

  # テスト環境では CSRF（リクエスト偽造）対策を無効にします。
  config.action_controller.allow_forgery_protection = false

  # アップロードされたファイルを、一時ディレクトリに保存します。
  config.active_storage.service = :test

  # Action Mailer が実際にはメールを送らないようにします。
  # :test の配信方式は、送ったメールを ActionMailer::Base.deliveries 配列にためます。
  config.action_mailer.delivery_method = :test

  # メールのテンプレートで作られるリンクのホスト名を設定します。
  config.action_mailer.default_url_options = { host: "example.com" }

  # 非推奨の警告を標準エラーに出します。
  config.active_support.deprecation = :stderr

  # 翻訳が見つからないときはエラーにします。
  # config.i18n.raise_on_missing_translations = true

  # 表示したビューにファイル名の注釈を付けます。
  # config.action_view.annotate_rendered_view_with_filenames = true

  # before_action の only/except に存在しないアクションを指定したら、エラーにします。
  config.action_controller.raise_on_missing_callback_actions = true
end
