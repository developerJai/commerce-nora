class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product_variant, optional: true

  validates :product_name, :variant_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :calculate_total_price, if: -> { quantity.present? && unit_price.present? }

  def self.from_cart_item(cart_item)
    new(
      product_variant: cart_item.product_variant,
      product_name: cart_item.product_variant.product.name,
      variant_name: cart_item.product_variant.name,
      sku: cart_item.product_variant.sku,
      quantity: cart_item.quantity,
      unit_price: cart_item.unit_price,
      total_price: cart_item.total_price
    )
  end

  private

  def calculate_total_price
    self.total_price = quantity * unit_price
  end
end
