class BundleDeal < ApplicationRecord
  has_many :bundle_deal_items, dependent: :destroy
  has_many :products, through: :bundle_deal_items

  has_one_attached :image

  accepts_nested_attributes_for :bundle_deal_items, allow_destroy: true

  validates :title, presence: true
  validates :original_price, presence: true, numericality: { greater_than: 0 }
  validates :discounted_price, presence: true, numericality: { greater_than: 0 }
  validates :discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validate :validate_image

  before_validation :calculate_discount_percentage

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }
  scope :visible, -> { active.ordered }

  def savings_amount
    original_price - discounted_price
  end

  def savings_display
    "SAVE #{discount_percentage}%"
  end

  def formatted_original_price
    "Rs. #{original_price.to_i}"
  end

  def formatted_discounted_price
    "Rs. #{discounted_price.to_i}"
  end

  def image_url
    return nil unless image.attached?
    Rails.application.routes.url_helpers.url_for(image)
  end

  private

  def calculate_discount_percentage
    return unless original_price.present? && discounted_price.present? && original_price > 0
    return if discount_percentage.present? && discount_percentage > 0

    self.discount_percentage = ((original_price - discounted_price) / original_price * 100).round
  end

  def validate_image
    return unless image.attached?

    unless image.blob.content_type.to_s.start_with?("image/")
      errors.add(:image, "must be an image file")
    end

    if image.blob.byte_size.to_i > 2.megabytes
      errors.add(:image, "must be smaller than 2 MB")
    end
  end
end
