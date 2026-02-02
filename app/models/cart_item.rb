class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product_variant

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_variant_id, uniqueness: { scope: :cart_id }

  before_validation :set_unit_price, if: -> { unit_price.blank? }

  delegate :product, :name, :sku, :in_stock?, :stock_quantity, to: :product_variant

  def total_price
    quantity * unit_price
  end

  def display_name
    product_variant.display_name
  end

  def available_quantity
    [product_variant.stock_quantity, quantity].min
  end

  def exceeds_stock?
    quantity > product_variant.stock_quantity
  end

  private

  def set_unit_price
    self.unit_price = product_variant&.price || 0
  end
end
