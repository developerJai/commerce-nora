class Product < ApplicationRecord
  include SoftDeletable
  belongs_to :category, optional: true
  has_many :variants, class_name: 'ProductVariant', dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many_attached :images

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :active, -> { where(active: true) }
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
end
