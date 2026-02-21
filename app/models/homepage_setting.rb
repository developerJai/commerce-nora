class HomepageSetting < ApplicationRecord
  validates :flash_sale_discount, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :flash_sale_title, presence: true, if: :flash_sale_enabled?
  validates :promo_banner_title, presence: true, if: :promo_banner_enabled?
  validates :bundle_deals_title, presence: true, if: :bundle_deals_enabled?

  # Singleton pattern - only one record should exist
  def self.current
    first_or_create!
  end

  def flash_sale_active?
    flash_sale_enabled? && (flash_sale_ends_at.nil? || flash_sale_ends_at > Time.current)
  end

  def formatted_discount
    "#{flash_sale_discount}% OFF"
  end

  def promo_code_display
    promo_banner_code.presence
  end
end
