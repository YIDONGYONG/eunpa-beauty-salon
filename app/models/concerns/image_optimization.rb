# アップロードされた写真を保存前に自動で縮小します（低スペックのサーバー／ディスク容量の節約）。
#
# - 長辺を基準に MAX_EDGE(px) 以下へ縮小し、WebP に変換して保存（品質は QUALITY。ADR 0008）
# - スマホ写真の回転情報（EXIF）を反映し、位置情報などのメタデータは削除
# - libvips がない環境（ローカル開発など）では原本のまま保存します。
# - GIF はアニメーションが壊れる恐れがあるため触りません。
# - 元ファイルが UPLOAD_MAX_MB を超えるものは変換せず、検証エラーにします（巨大ファイルの処理でメモリを使わない）。
#
# 使い方: optimize_images :photo, :gallery_images
module ImageOptimization
  extend ActiveSupport::Concern

  MAX_EDGE = Integer(ENV.fetch("IMAGE_MAX_EDGE", 1600))
  QUALITY = Integer(ENV.fetch("IMAGE_QUALITY", 82))
  OPTIMIZABLE = %w[image/jpeg image/png image/webp].freeze

  class_methods do
    def optimize_images(*names)
      names.each do |name|
        define_method(:"#{name}=") do |value|
          super(value.is_a?(Array) ? value.map { |v| ImageOptimization.optimize(v) } : ImageOptimization.optimize(value))
        end
      end
    end
  end

  # 中身を見て画像かどうか判定（宣言した種類・拡張子は使わない）。画像でないと ImageValidation が拒否する
  def self.real_image?(upload)
    detected = Marcel::MimeType.for(upload.tempfile, declared_type: nil, name: nil)
    upload.tempfile.rewind
    ImageValidation::ALLOWED_TYPES.include?(detected)
  rescue StandardError
    false
  end

  INVALID_UPLOAD = lambda do |upload|
    { io: StringIO.new(""), filename: upload.original_filename.to_s, content_type: "application/x-invalid-image" }
  end

  def self.vips_available?
    return @vips_available if defined?(@vips_available)

    @vips_available =
      begin
        require "image_processing/vips"
        true
      rescue LoadError
        false
      end
  end

  # ActionDispatch::Http::UploadedFile のみ処理し、それ以外（保存済みの blob など）はそのまま返します。
  def self.optimize(upload)
    return upload unless upload.respond_to?(:tempfile) && upload.respond_to?(:content_type)
    # 申告された content_type は偽装できる。ファイルの中身（マジックバイト）が画像でなければ受け付けない
    return INVALID_UPLOAD.call(upload) unless real_image?(upload)
    return upload unless vips_available? && OPTIMIZABLE.include?(upload.content_type)
    return upload if upload.size > Rails.configuration.x.upload_max_size

    result = ImageProcessing::Vips
             .source(upload.tempfile)
             .autorot
             .resize_to_limit(MAX_EDGE, MAX_EDGE)
             .convert("webp")
             .saver(strip: true, quality: QUALITY)
             .call
    # PNG の透過も WebP で保持されます。ファイル名の拡張子も .webp にそろえます。
    filename = "#{File.basename(upload.original_filename.to_s, '.*')}.webp"
    { io: File.open(result.path), filename: filename, content_type: "image/webp" }
  rescue StandardError => e
    Rails.logger.warn("[ImageOptimization] skipped: #{e.class}: #{e.message}")
    upload.tempfile.rewind if upload.respond_to?(:tempfile)
    upload
  end
end
