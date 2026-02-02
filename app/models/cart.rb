class Cart < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :product_variants, through: :cart_items

  STATUSES = %w[active abandoned converted].freeze

  validates :token, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  before_validation :generate_token, if: -> { token.blank? }

  scope :active, -> { where(status: 'active') }
  scope :abandoned, -> { where(status: 'abandoned') }

  def add_item(variant, quantity = 1)
    item = cart_items.find_by(product_variant: variant)
    if item
      item.update!(quantity: item.quantity + quantity)
      item
    else
      cart_items.create!(product_variant: variant, quantity: quantity, unit_price: variant.price)
    end
  end

  def update_item(variant, quantity)
    item = cart_items.find_by(product_variant: variant)
    return unless item

    if quantity <= 0
      item.destroy
    else
      item.update!(quantity: quantity)
    end
  end

  def remove_item(variant)
    cart_items.find_by(product_variant: variant)&.destroy
  end

  def subtotal
    cart_items.sum { |item| item.total_price }
  end

  def item_count
    cart_items.sum(:quantity)
  end

  def empty?
    cart_items.empty?
  end

  def clear!
    cart_items.destroy_all
  end

  def merge_with!(other_cart)
    return if other_cart.nil? || other_cart == self

    other_cart.cart_items.each do |item|
      add_item(item.product_variant, item.quantity)
    end
    other_cart.destroy
  end

  def mark_as_converted!
    update!(status: 'converted')
  end

  private

  def generate_token
    self.token = SecureRandom.uuid
  end
end
