class VendorPayout < ApplicationRecord
  belongs_to :vendor
  has_many :vendor_payout_orders, dependent: :destroy
  has_many :orders, through: :vendor_payout_orders

  STATUSES = %w[pending approved paid rejected].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :total_amount, :platform_fee_total, :gateway_fee_total, :gateway_gst_total, :net_payout, numericality: { greater_than_or_equal_to: 0 }

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :paid, -> { where(status: "paid") }
  scope :rejected, -> { where(status: "rejected") }
  scope :recent, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def paid?
    status == "paid"
  end

  def rejected?
    status == "rejected"
  end

  def approve!(notes = nil)
    return false unless pending?

    update!(
      status: "approved",
      approved_at: Time.current,
      admin_notes: notes
    )
  end

  def mark_as_paid!(transaction_reference, notes = nil)
    return false unless approved?

    transaction do
      update!(
        status: "paid",
        paid_at: Time.current,
        transaction_reference: transaction_reference,
        admin_notes: [ admin_notes, notes ].compact.join("\n")
      )

      # Mark all associated orders as paid
      orders.update_all(payout_status: "paid")
    end

    true
  end

  def reject!(notes = nil)
    return false unless pending?

    transaction do
      update!(
        status: "rejected",
        rejected_at: Time.current,
        admin_notes: notes
      )

      # Release orders back to pending status
      orders.update_all(payout_status: "pending")
    end

    true
  end

  def order_breakdown
    orders.map do |order|
      {
        order_id: order.id,
        order_number: order.order_number,
        total_amount: order.total_amount,
        platform_fee: order.platform_fee_amount,
        gateway_fee: order.gateway_fee_amount,
        gateway_gst: order.gateway_gst_amount,
        vendor_earnings: order.vendor_earnings,
        delivered_at: order.delivered_at
      }
    end
  end
end
