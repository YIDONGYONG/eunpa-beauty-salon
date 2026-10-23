# アップロードされた写真を保存前に自動で縮小します（低スペックのサーバー／ディスク容量の節約）。
#
# - 長辺を基準に MAX_EDGE(px) 以下へ縮小、JPEG/WEBP の品質は QUALITY
# - スマホ写真の回転情報（EXIF）を反映し、位置情報などのメタデータは削除
# - libvips がない環境（ローカル開発など）では原本のまま保存します。
# - GIF はアニメーションが壊れる恐れがあるため触りません。
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
    return upload unless vips_available? && upload.respond_to?(:tempfile) && upload.respond_to?(:content_type)
    return upload unless OPTIMIZABLE.include?(upload.content_type)

    result = ImageProcessing::Vips
             .source(upload.tempfile)
             .autorot
             .resize_to_limit(MAX_EDGE, MAX_EDGE)
             .saver(strip: true, quality: QUALITY)
             .call
    # PNG は透過背景の可能性があるため形式を維持し、それ以外は元の形式で保存します。
    { io: File.open(result.path), filename: upload.original_filename, content_type: upload.content_type }
  rescue StandardError => e
    Rails.logger.warn("[ImageOptimization] skipped: #{e.class}: #{e.message}")
    upload.tempfile.rewind if upload.respond_to?(:tempfile)
    upload
  end
end
