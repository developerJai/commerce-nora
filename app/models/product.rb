class Product < ApplicationRecord
  include SoftDeletable
  include OrganizedUploads

  # ── Associations ──────────────────────────────────────────────────
  belongs_to :category, optional: true
  belongs_to :vendor, optional: true
  belongs_to :hsn_code, optional: true

  upload_key_prefix do
    vendor_id ? "vendors/#{vendor_id}/products" : "products"
  end
  has_many :variants, class_name: "ProductVariant", dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy, class_name: "Wishlist"
  has_many :wishing_customers, through: :wishlist_items, source: :customer
  has_many_attached :images

  accepts_nested_attributes_for :variants, reject_if: :all_blank, allow_destroy: true

  # ── Validations ───────────────────────────────────────────────────
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :sku, uniqueness: true, allow_blank: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_validation :generate_sku, if: -> { sku.blank? && name.present? }

  validate :validate_images
  validate :must_have_at_least_one_variant, on: :create
  validate :validate_attribute_options

  scope :active, -> {
    left_joins(:vendor).where(products: { active: true })
                       .where("vendors.active IS NULL OR vendors.active = ?", true)
  }
  scope :featured, -> { where(featured: true) }
  scope :hot_selling, -> { where(hot_selling: true) }
  scope :with_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :search, ->(query) {
    where("name ILIKE :q OR description ILIKE :q OR short_description ILIKE :q", q: "%#{query}%") if query.present?
  }
  scope :by_price_range, ->(min, max) {
    joins(:variants).where(product_variants: { active: true })
      .where("product_variants.price >= ?", min) if min.present?
  }
  scope :ordered, -> { order(created_at: :desc) }

  # ── Storefront filter scopes ────────────────────────────────────

  # Filter by product column attribute (base_material, plating, gemstone, occasion, ideal_for)
  scope :by_attribute, ->(attr_name, values) {
    return none unless Category::PRODUCT_COLUMN_ATTRIBUTES.include?(attr_name.to_s)
    where(attr_name => values) if values.present?
  }

  # Filter by JSONB properties key
  scope :by_property, ->(key, values) {
    where("properties ->> ? IN (?)", key.to_s, Array(values)) if values.present?
  }

  # Filter by variant color
  scope :by_color, ->(colors) {
    return all unless colors.present?
    joins(:variants)
      .where(product_variants: { active: true, color: colors })
      .distinct
  }

  # Filter by minimum discount percentage
  scope :by_discount, ->(min_pct) {
    return all unless min_pct.to_i > 0
    joins(:variants)
      .where(product_variants: { active: true })
      .where("product_variants.compare_at_price > product_variants.price")
      .where("((product_variants.compare_at_price - product_variants.price) / product_variants.compare_at_price * 100) >= ?", min_pct.to_i)
      .distinct
  }

  # Filter by minimum rating
  scope :by_rating, ->(min_rating) {
    where("average_rating >= ?", min_rating.to_f) if min_rating.present? && min_rating.to_f > 0
  }

  # Filter only in-stock products
  scope :in_stock_only, -> {
    joins(:variants)
      .where(product_variants: { active: true })
      .where("product_variants.stock_quantity > 0")
      .distinct
  }

  # Collect available filter values from a product scope (for faceted counts)
  def self.available_filter_values(attr_name)
    if Category::PRODUCT_COLUMN_ATTRIBUTES.include?(attr_name.to_s)
      where.not(attr_name => [ nil, "" ]).group(attr_name).count
    else
      # JSONB property
      where("properties ->> ? IS NOT NULL AND properties ->> ? != ''", attr_name, attr_name)
        .group(Arel.sql("properties ->> '#{attr_name}'")).count
    end
  end

  # Variant color facet counts
  # Always joins variants to ensure consistent behavior
  def self.available_colors
    joins(:variants)
      .where(product_variants: { active: true })
      .where.not(product_variants: { color: [ nil, "" ] })
      .group("product_variants.color").count
  end

  def default_variant
    variants.active.order(:position).first || variants.first
  end

  # Get first in-stock variant (for display when in-stock filter is active)
  def first_in_stock_variant
    variants.active.where("stock_quantity > 0").order(:position).first
  end

  def price_range
    prices = variants.active.pluck(:price).compact
    return nil if prices.empty?
    prices.minmax
  end

  def min_price
    variants.active.minimum(:price) || price
  end

  def in_stock?
    variants.active.where("stock_quantity > 0").exists?
  end

  def approved_reviews
    reviews.where(approved: true)
  end

  def update_rating!
    approved = approved_reviews
    if approved.any?
      self.average_rating = approved.average(:rating).round(2)
      self.ratings_count = approved.count
    else
      self.average_rating = 0
      self.ratings_count = 0
    end
    save!
  end

  # ── Category-aware attribute helpers ──────────────────────────────

  # Returns the attribute definitions for this product's category
  def product_attribute_definitions
    category&.product_attribute_definitions || []
  end

  # Get value for a category-driven attribute (checks column first, then properties)
  def attribute_value(key)
    key = key.to_s
    if respond_to?(key) && Category::PRODUCT_COLUMN_ATTRIBUTES.include?(key)
      send(key)
    else
      properties&.dig(key)
    end
  end

  # Set value for a category-driven attribute
  def set_attribute_value(key, value)
    key = key.to_s
    if respond_to?("#{key}=") && Category::PRODUCT_COLUMN_ATTRIBUTES.include?(key)
      send("#{key}=", value)
    else
      self.properties = (properties || {}).merge(key => value)
    end
  end

  # Returns all filled attribute values as { label => value } for display
  def filled_attributes
    return {} unless category

    category.product_attribute_definitions.each_with_object({}) do |defn, hash|
      val = attribute_value(defn[:key])
      hash[defn[:label]] = val if val.present?
    end
  end

  private

  def validate_attribute_options
    return unless category

    category.product_attribute_definitions.each do |defn|
      value = attribute_value(defn[:key])
      next if value.blank?

      options = defn[:options]
      if options.present? && !options.include?(value)
        errors.add(defn[:key].to_sym, "#{value} is not a valid option for #{defn[:label]}")
      end
    end
  end

  def must_have_at_least_one_variant
    if variants.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "Product must have at least one variant with price and stock")
    end
  end

  def generate_slug
    base_slug = name.parameterize
    slug_candidate = base_slug
    counter = 1
    while Product.exists?(slug: slug_candidate)
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end
    self.slug = slug_candidate
  end

  def generate_sku
    base = name.parameterize.upcase.gsub("-", "")
    base = base[0, 12] if base.length > 12
    prefix = base.presence || "PRD"

    sku_candidate = nil
    20.times do
      candidate = "#{prefix}-#{SecureRandom.hex(2).upcase}"
      next if Product.exists?(sku: candidate)
      sku_candidate = candidate
      break
    end

    self.sku = sku_candidate || "#{prefix}-#{SecureRandom.hex(3).upcase}"
  end

  MAX_IMAGES = 15

  def validate_images
    return unless images.attached?

    if images.count > MAX_IMAGES
      errors.add(:images, "cannot exceed #{MAX_IMAGES} images")
      return
    end

    images.each do |img|
      next unless img.blob

      unless img.blob.content_type.to_s.start_with?("image/")
        errors.add(:images, "must be an image")
      end

      if img.blob.byte_size.to_i > 2.megabytes
        errors.add(:images, "must be smaller than 2 MB")
      end
    end
  end
end
