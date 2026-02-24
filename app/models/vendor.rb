class Vendor < ApplicationRecord
  include SoftDeletable

  has_many :admin_users, dependent: :nullify
  has_many :products, dependent: :nullify
  has_many :orders, dependent: :nullify
  has_many :support_tickets, dependent: :nullify
  has_many :vendor_payouts, dependent: :nullify

  validates :business_name, presence: true
  validates :contact_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :gst_number, length: { is: 15 }, allow_blank: true,
            format: { with: /\A[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}\z/, message: "must be a valid 15-character GST number" }

  before_save :downcase_email

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(business_name: :asc) }

  def display_name
    business_name
  end

  # Earnings calculations
  def total_earnings
    orders.where(payment_status: "paid").sum(:vendor_earnings)
  end

  def available_for_payout
    orders.ready_for_payout.sum(:vendor_earnings)
  end

  def pending_earnings
    # Calculate actual earnings after fees for pending orders
    # Pending orders are those that are confirmed/processing/shipped but not yet paid/delivered
    pending_orders = orders.where(status: %w[confirmed processing shipped], payment_status: "pending")

    pending_orders.sum do |order|
      if order.vendor_earnings.present? && order.vendor_earnings > 0
        # Use stored vendor earnings if available
        order.vendor_earnings
      else
        # Calculate projected earnings
        config = PlatformFeeConfig.current
        fees = config.calculate_fees(order.total_amount)
        fees[:vendor_earnings]
      end
    end
  end

  def paid_out_total
    vendor_payouts.paid.sum(:net_payout)
  end

  def ready_orders_for_payout
    orders.ready_for_payout.order(delivered_at: :asc)
  end

  def has_pending_payout_request?
    vendor_payouts.where(status: %w[pending approved]).exists?
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
