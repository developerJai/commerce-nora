class BundleDealItem < ApplicationRecord
  belongs_to :bundle_deal
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :bundle_deal_id }

  scope :ordered, -> { order(position: :asc) }
end
