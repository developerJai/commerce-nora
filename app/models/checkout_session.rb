class CheckoutSession < ApplicationRecord
  belongs_to :customer
  has_many :orders, dependent: :nullify

  STATUSES = %w[pending paid failed refunded partially_refunded].freeze
  PAYMENT_METHODS = %w[cod razorpay].freeze

  validates :batch_id, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :payment_method, presence: true, inclusion: { in: PAYMENT_METHODS }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }
  scope :failed, -> { where(status: "failed") }
  scope :refunded, -> { where(status: "refunded") }

  def paid?
    status == "paid"
  end

  def pending?
    status == "pending"
  end

  def failed?
    status == "failed"
  end

  def refunded?
    status == "refunded"
  end

  def partially_refunded?
    status == "partially_refunded"
  end

  def mark_as_paid!(razorpay_payment_id = nil)
    update!(
      status: "paid",
      paid_at: Time.current,
      razorpay_payment_id: razorpay_payment_id
    )
  end

  def mark_as_failed!(error_message = nil)
    update!(
      status: "failed",
      failed_at: Time.current,
      error_message: error_message
    )
  end

  def total_refunded_amount
    orders.where(refund_status: "paid").sum(:refund_amount)
  end

  def refund_amount_available
    total_amount - total_refunded_amount
  end

  def update_refund_status!
    orders_with_refunds = orders.where.not(refund_status: "not_refunded").count
    orders_total = orders.count

    if orders_with_refunds == 0
      # No refunds
    elsif orders_with_refunds == orders_total
      update!(status: "refunded") if paid?
    else
      update!(status: "partially_refunded") if paid?
    end
  end
end
