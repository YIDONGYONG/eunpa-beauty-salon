# このファイルは、Rack ベースのサーバーがアプリを起動するために使います。

require_relative "config/environment"

run Rails.application
Rails.application.load_server
