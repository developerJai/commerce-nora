class ProductVariant < ApplicationRecord
  include SoftDeletable
  belongs_to :product
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :nullify
  has_many :stock_adjustments, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_sku, if: -> { sku.blank? }

  validate :validate_image

  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :out_of_stock, -> { where(stock_quantity: 0) }
  scope :low_stock, -> { where("stock_quantity > 0 AND stock_quantity <= reorder_point") }
  scope :needs_reorder, -> { where("track_inventory = true AND stock_quantity <= reorder_point") }
  scope :ordered, -> { order(:position, :name) }

  def in_stock?
    stock_quantity > 0
  end

  def out_of_stock?
    stock_quantity == 0
  end

  def low_stock?
    stock_quantity > 0 && stock_quantity <= (reorder_point || 10)
  end

  def needs_reorder?
    track_inventory? && stock_quantity <= (reorder_point || 10)
  end

  def stock_status
    return :out_of_stock if out_of_stock?
    return :low_stock if low_stock?
    :in_stock
  end

  def display_name
    "#{product.name} - #{name}"
  end

  def on_sale?
    compare_at_price.present? && compare_at_price > price
  end

  def discount_percentage
    return 0 unless on_sale?
    ((compare_at_price - price) / compare_at_price * 100).round
  end

  # Adjust stock with tracking
  def adjust_stock!(quantity_change, reason:, notes: nil, adjusted_by: nil)
    with_lock do
      old_quantity = stock_quantity
      new_quantity = old_quantity + quantity_change
      
      raise "Cannot have negative stock" if new_quantity < 0
      
      transaction do
        update!(stock_quantity: new_quantity)
        
        stock_adjustments.create!(
          quantity_change: quantity_change,
          quantity_before: old_quantity,
          quantity_after: new_quantity,
          reason: reason,
          notes: notes,
          adjusted_by: adjusted_by
        )
      end
      
      new_quantity
    end
  end

  # Convenience methods for common adjustments
  def restock!(quantity, notes: nil, adjusted_by: nil)
    adjust_stock!(quantity, reason: 'restock', notes: notes, adjusted_by: adjusted_by)
  end

  def record_sale!(quantity, notes: nil, adjusted_by: nil)
    adjust_stock!(-quantity, reason: 'sale', notes: notes, adjusted_by: adjusted_by)
  end

  def record_return!(quantity, notes: nil, adjusted_by: nil)
    adjust_stock!(quantity, reason: 'return', notes: notes, adjusted_by: adjusted_by)
  end

  def record_damage!(quantity, notes: nil, adjusted_by: nil)
    adjust_stock!(-quantity, reason: 'damage', notes: notes, adjusted_by: adjusted_by)
  end

  def correct_stock!(new_quantity, notes: nil, adjusted_by: nil)
    change = new_quantity - stock_quantity
    adjust_stock!(change, reason: 'correction', notes: notes, adjusted_by: adjusted_by)
  end

  # Legacy methods (deprecated - use adjust_stock! instead)
  def decrement_stock!(quantity)
    adjust_stock!(-quantity, reason: 'sale')
  end

  def increment_stock!(quantity)
    adjust_stock!(quantity, reason: 'restock')
  end

  private

  def generate_sku
    base = product&.sku.presence || "PRD"

    sku_candidate = nil
    20.times do
      candidate = "#{base}-#{SecureRandom.hex(3).upcase}"
      next if ProductVariant.exists?(sku: candidate)
      sku_candidate = candidate
      break
    end

    self.sku = sku_candidate || "#{base}-#{SecureRandom.hex(4).upcase}"
  end

  def validate_image
    return unless image.attached?
    return unless image.blob

    unless image.blob.content_type.to_s.start_with?("image/")
      errors.add(:image, "must be an image")
    end

    if image.blob.byte_size.to_i > 2.megabytes
      errors.add(:image, "must be smaller than 2 MB")
    end
  end
end
