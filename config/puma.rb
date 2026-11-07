# このファイルは Puma が読み込む設定です。ここで呼ぶ最上位のメソッドは Puma の設定 DSL です。
# DSL のメソッドの詳細は https://puma.io/puma/Puma/DSL.html を参照してください。
#
# Puma は設定した数のプロセス（ワーカー）を起動し、各プロセスは内部のスレッドプールのスレッドでリクエストを処理します。
#
# ワーカー数は ENV["WEB_CONCURRENCY"] で指定できます。2 以上にしたいときだけ設定してください（既定は 1）。
# `auto` にすると、使える CPU ごとにワーカーを1つ起動します。
#
# ワーカーあたりの最適なスレッド数は、アプリが IO の待ち時間にどれだけ使うか、
# スループットと応答時間のどちらを優先するかによって変わります。
#
# 目安として、スレッドを増やすとプロセスが処理できる量（スループット）は増えますが、
# CRuby の GVL（グローバルVMロック）のため効果は次第に小さくなり、応答時間は悪化します。
#
# 既定は 3 スレッドです。一般的な Rails アプリでは、スループットと応答時間のほどよい妥協点とされています。
#
# コネクションプールなどを使うライブラリは、少なくともスレッド数と同じ数の接続を使えるよう設定してください。
# Active Record では database.yml の `pool` がこれに当たります。
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)

# メモリ節約: ワーカープロセスなしの単一プロセス（スレッドのみ）で実行。サーバーに余裕があれば WEB_CONCURRENCY=2 などに上げます。
workers ENV.fetch("WEB_CONCURRENCY", 0).to_i
preload_app! if ENV.fetch("WEB_CONCURRENCY", 0).to_i > 0
threads threads_count, threads_count

# Puma がリクエストを受け付ける `port` を指定します（既定は 3000）。
port ENV.fetch("PORT", 3000)

# `bin/rails restart` コマンドで Puma を再起動できるようにします。
plugin :tmp_restart

# Solid Queue を Puma プロセスの中で動かす（コンテナ1つ・メモリ節約）。本番では SOLID_QUEUE_IN_PUMA=true
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# PID ファイルを指定します。開発環境の既定は tmp/pids/server.pid です。
# それ以外の環境では、指定されたときだけ PID ファイルを作ります。
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
