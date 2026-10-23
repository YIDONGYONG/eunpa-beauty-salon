# アップロード画像の形式／サイズ制限。`validates_image :photo` の形で使います。
module ImageValidation
  extend ActiveSupport::Concern

  ALLOWED_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze

  class_methods do
    def validates_image(*names)
      names.each do |name|
        validate do
          Array(public_send(name).attachments).each do |attachment|
            blob = attachment.blob
            unless ALLOWED_TYPES.include?(blob.content_type)
              errors.add(name, "은(는) JPG, PNG, WEBP, GIF 사진만 올릴 수 있습니다.")
            end
            if blob.byte_size > Rails.configuration.x.upload_max_size
              limit = Rails.configuration.x.upload_max_size / 1.megabyte
              errors.add(name, "은(는) #{limit}MB 이하의 사진만 올릴 수 있습니다.")
            end
          end
        end
      end
    end
  end
end
