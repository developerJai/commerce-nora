class Wishlist < ApplicationRecord
  belongs_to :customer
  belongs_to :product
  belongs_to :product_variant, optional: true

  validates :customer_id, uniqueness: { scope: [:product_id, :product_variant_id] }
end
