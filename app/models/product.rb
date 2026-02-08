class Product < ApplicationRecord
  include SoftDeletable
  include OrganizedUploads

  belongs_to :category, optional: true
  belongs_to :vendor, optional: true
  belongs_to :hsn_code, optional: true

  upload_key_prefix do
    vendor_id ? "vendors/#{vendor_id}/products" : "products"
  end
  has_many :variants, class_name: 'ProductVariant', dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy, class_name: 'Wishlist'
  has_many :wishing_customers, through: :wishlist_items, source: :customer
  has_many_attached :images

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :sku, uniqueness: true, allow_blank: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_validation :generate_sku, if: -> { sku.blank? && name.present? }

  validate :validate_images

  scope :active, -> {
    left_joins(:vendor).where(products: { active: true })
                       .where("vendors.active IS NULL OR vendors.active = ?", true)
  }
  scope :featured, -> { where(featured: true) }
  scope :with_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :search, ->(query) {
    where("name ILIKE :q OR description ILIKE :q OR short_description ILIKE :q", q: "%#{query}%") if query.present?
  }
  scope :by_price_range, ->(min, max) {
    joins(:variants).where(product_variants: { active: true })
      .where("product_variants.price >= ?", min) if min.present?
  }
  scope :ordered, -> { order(created_at: :desc) }

  def default_variant
    variants.active.order(:position).first || variants.first
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

  private

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

  def validate_images
    return unless images.attached?

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
