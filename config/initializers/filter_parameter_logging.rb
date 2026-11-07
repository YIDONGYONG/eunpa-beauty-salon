# このファイルを変更したら、サーバーを再起動してください。

# 部分一致（例: passw は password に一致）するパラメータを、ログから除外（フィルタ）します。
# 機密情報が広まるのを防ぐために使います。
# 指定できる書き方や動作は、ActiveSupport::ParameterFilter のドキュメントを参照してください。
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]
