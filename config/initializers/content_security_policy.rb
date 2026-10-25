# Content Security Policy（XSS 対策。外部から読み込むものだけを許可リストで指定）
#  - スクリプトは自サイトと NAVER 地図のみ。インライン script（importmap）は nonce で許可
#  - スタイルは NAVER 地図が inline style を挿入するため 'unsafe-inline' を許可（スクリプトは許可しない）
#  - フォントは Google Fonts
Rails.application.configure do
  config.content_security_policy do |policy|
    naver = %w[https://*.naver.com https://*.naver.net https://*.pstatic.net]
    policy.default_src :self
    policy.script_src  :self, "https://openapi.map.naver.com", *naver
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com", *naver
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :blob, *naver
    policy.connect_src :self, *naver
    policy.frame_src   :none
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
