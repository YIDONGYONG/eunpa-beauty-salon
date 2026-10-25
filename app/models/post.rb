class Post < ApplicationRecord
  include Translatable
  include ImageValidation
  include ImageOptimization
  include SoftDeletable

  PER_PAGE = 6

  translates :title

  Translatable::LOCALES.each { |l| has_rich_text :"content_#{l}" }
  has_one_attached :featured_image

  validates :title_ko, presence: true, length: { maximum: 120 }
  optimize_images :featured_image
  validates_image :featured_image

  before_save :stamp_published_at

  scope :published, -> { kept.where(published: true) }
  scope :latest, -> { order(published_at: :desc, id: :desc) }

  def self.page(number)
    offset([ number.to_i, 1 ].max.pred * PER_PAGE).limit(PER_PAGE)
  end

  def self.total_pages
    [ (published.count / PER_PAGE.to_f).ceil, 1 ].max
  end

  # 現在の言語の本文（空なら韓国語の本文）
  def content(locale = I18n.locale)
    body = public_send(:"content_#{locale}")
    body = content_ko if body.blank?
    body
  end

  def content_translated?(locale = I18n.locale)
    public_send(:"content_#{locale}").present?
  end

  def excerpt(length = 80)
    content.to_plain_text.squish.truncate(length)
  end

  private

  def stamp_published_at
    if published? && published_at.blank?
      self.published_at = Time.current
    end
  end
end
