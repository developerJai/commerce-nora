class StoreSetting < ApplicationRecord
  # Singleton pattern — one row for the entire store.
  # Access via StoreSetting.instance

  # Company details for invoices
  # gst_number, company_address, company_phone are persisted columns

  FILTER_KEYS = %w[
    show_availability
    show_categories
    show_subcategories
    show_price_range
    show_color
    show_material
    show_stone_type
    show_occasion
    show_discount
    show_rating
  ].freeze

  FILTER_DEFAULTS = {
    "show_availability"  => true,
    "show_categories"    => true,
    "show_subcategories" => true,
    "show_price_range"   => true,
    "show_color"         => true,
    "show_material"      => true,
    "show_stone_type"    => true,
    "show_occasion"      => true,
    "show_discount"      => true,
    "show_rating"        => true
  }.freeze

  PAYMENT_KEYS = %w[
    enable_razorpay
    enable_cod
  ].freeze

  PAYMENT_DEFAULTS = {
    "enable_razorpay" => true,
    "enable_cod" => true
  }.freeze

  # Returns (or creates) the single settings row.
  def self.instance
    first_or_create!(
      filter_config: FILTER_DEFAULTS,
      payment_config: PAYMENT_DEFAULTS
    )
  end

  # Convenience: is a specific filter enabled?
  def filter_enabled?(key)
    config = filter_config.presence || FILTER_DEFAULTS
    config.fetch(key.to_s, true)
  end

  # Returns a hash of all filter flags with defaults filled in.
  def effective_filter_config
    FILTER_DEFAULTS.merge(filter_config.presence || {})
  end

  # Payment method checks
  def razorpay_enabled?
    config = payment_config.presence || PAYMENT_DEFAULTS
    config.fetch("enable_razorpay", true)
  end

  def cod_enabled?
    config = payment_config.presence || PAYMENT_DEFAULTS
    config.fetch("enable_cod", true)
  end

  def any_payment_method_enabled?
    razorpay_enabled? || cod_enabled?
  end

  def effective_payment_config
    PAYMENT_DEFAULTS.merge(payment_config.presence || {})
  end

  # Coupon settings
  def coupons_enabled?
    enable_coupons.nil? ? true : enable_coupons
  end
end
