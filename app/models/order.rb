class Order < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :shipping_address, class_name: 'Address', optional: true
  belongs_to :billing_address, class_name: 'Address', optional: true
  belongs_to :coupon, optional: true
  has_many :order_items, dependent: :destroy
  has_many :reviews, dependent: :nullify
  has_many :support_tickets, dependent: :nullify

  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :all_blank

  STATUSES = %w[pending confirmed processing shipped delivered cancelled].freeze
  PAYMENT_STATUSES = %w[pending paid failed refunded].freeze
  PAYMENT_METHODS = %w[cod].freeze

  validates :order_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :payment_status, presence: true, inclusion: { in: PAYMENT_STATUSES }
  validates :payment_method, presence: true, inclusion: { in: PAYMENT_METHODS }

  before_validation :generate_order_number, if: -> { order_number.blank? }

  scope :active, -> { where.not(status: 'cancelled') }
  scope :draft, -> { where(is_draft: true) }
  scope :placed, -> { where(is_draft: false).where.not(placed_at: nil) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }

  def place!
    return false if is_draft? && order_items.empty?

    transaction do
      # Decrement stock
      order_items.each do |item|
        item.product_variant&.decrement_stock!(item.quantity)
      end

      # Increment coupon usage
      coupon&.increment_usage!

      update!(
        is_draft: false,
        placed_at: Time.current,
        status: 'confirmed'
      )
    end
    true
  rescue => e
    errors.add(:base, e.message)
    false
  end

  def confirm!
    update!(status: 'confirmed')
  end

  def process!
    update!(status: 'processing')
  end

  def ship!
    update!(status: 'shipped', shipped_at: Time.current)
  end

  def deliver!
    update!(status: 'delivered', delivered_at: Time.current, payment_status: 'paid')
  end

  def cancel!
    return false if delivered?

    transaction do
      # Restore stock
      order_items.each do |item|
        item.product_variant&.increment_stock!(item.quantity)
      end

      # Decrement coupon usage
      coupon&.decrement_usage!

      update!(status: 'cancelled', cancelled_at: Time.current)
    end
    true
  end

  def pending?
    status == 'pending'
  end

  def confirmed?
    status == 'confirmed'
  end

  def processing?
    status == 'processing'
  end

  def shipped?
    status == 'shipped'
  end

  def delivered?
    status == 'delivered'
  end

  def cancelled?
    status == 'cancelled'
  end

  def can_cancel?
    !delivered? && !cancelled?
  end

  def can_review?
    delivered?
  end

  def calculate_totals!
    self.subtotal = order_items.sum(&:total_price)
    self.discount_amount = coupon&.calculate_discount(subtotal) || 0
    self.total_amount = subtotal - discount_amount + shipping_amount + tax_amount
  end

  def items_count
    order_items.sum(:quantity)
  end

  private

  def generate_order_number
    loop do
      self.order_number = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless Order.exists?(order_number: order_number)
    end
  end
end
