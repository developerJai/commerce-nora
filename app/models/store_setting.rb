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

  def multi_vendor_coupons_enabled?
    enable_multi_vendor_coupons
  end

  # Delivery settings
  def effective_free_delivery_min_amount
    free_delivery_min_amount.presence || 499.0
  end

  def effective_delivery_charge_amount
    delivery_charge_amount.presence || 99.0
  end

  # Banner colors
  BANNER_DEFAULTS = {
    bg_color: "#7A0C14",
    text_color: "#FFFFFF",
    accent_color: "#FFD700"
  }.freeze

  def effective_banner_bg_color
    banner_bg_color.presence || BANNER_DEFAULTS[:bg_color]
  end

  def effective_banner_text_color
    banner_text_color.presence || BANNER_DEFAULTS[:text_color]
  end

  def effective_banner_accent_color
    banner_accent_color.presence || BANNER_DEFAULTS[:accent_color]
  end

  # Contact info
  def has_contact_info?
    contact_email.present? || company_phone.present?
  end

  # Social media URLs
  def social_media_links
    {
      youtube: youtube_url,
      instagram: instagram_url,
      facebook: facebook_url,
      twitter: twitter_url
    }.compact_blank
  end

  def has_social_links?
    social_media_links.any?
  end

  # Mobile app settings
  def mobile_apps_enabled?
    mobile_apps_enabled
  end

  def has_mobile_apps?
    mobile_apps_enabled? && (ios_app_url.present? || android_app_url.present?)
  end

  def effective_mobile_app_section_title
    mobile_app_section_title.presence || "Shop on the Go"
  end

  def effective_mobile_app_section_subtitle
    mobile_app_section_subtitle.presence || "Download our app for exclusive deals, faster checkout, and a personalised shopping experience"
  end

  def effective_smart_banner_title
    smart_banner_title.presence || "Noralooks"
  end

  def effective_smart_banner_subtitle
    smart_banner_subtitle.presence || "Download our app for great offers & deals"
  end

  # Class-level convenience for use in views/models without fetching full instance
  def self.free_delivery_threshold
    instance.effective_free_delivery_min_amount.to_f
  end

  def self.flat_delivery_charge
    instance.effective_delivery_charge_amount.to_f
  end
end
