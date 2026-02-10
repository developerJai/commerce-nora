class StoreSetting < ApplicationRecord
  # Singleton pattern — one row for the entire store.
  # Access via StoreSetting.instance

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

  # Returns (or creates) the single settings row.
  def self.instance
    first_or_create!(filter_config: FILTER_DEFAULTS)
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
end
