class Review < ApplicationRecord
  include SoftDeletable
  belongs_to :product
  belongs_to :customer, optional: true
  belongs_to :order, optional: true

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :product_id, uniqueness: { scope: :order_id }, if: -> { order_id.present? }

  after_save :update_product_rating
  after_destroy :update_product_rating

  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }
  scope :recent, -> { order(created_at: :desc) }

  def approve!
    update!(approved: true, approved_at: Time.current)
  end

  def reject!
    update!(approved: false, approved_at: nil)
  end

  def customer_name
    customer&.full_name || "Anonymous"
  end

  def has_admin_response?
    admin_response.present?
  end

  private

  def update_product_rating
    product.update_rating!
  end
end
