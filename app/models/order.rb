class Order < ApplicationRecord
  # ── Value object returned by shipping_address / billing_address ──
  # Mirrors the Address model interface so views work without changes.
  class AddressSnapshot
    attr_reader :first_name, :last_name, :phone,
                :street_address, :apartment, :city, :state, :postal_code, :country

    def initialize(data)
      data = (data || {}).with_indifferent_access
      @first_name     = data[:first_name]
      @last_name      = data[:last_name]
      @phone          = data[:phone]
      @street_address = data[:street_address]
      @apartment      = data[:apartment]
      @city           = data[:city]
      @state          = data[:state]
      @postal_code    = data[:postal_code]
      @country        = data[:country]
    end

    def full_name
      [ first_name, last_name ].compact_blank.join(" ")
    end

    def full_address
      [ street_address, apartment, city, state, postal_code, country ].compact_blank.join(", ")
    end

    def one_line
      "#{full_name}, #{full_address}"
    end
  end

  # ── Associations ──
  belongs_to :customer, optional: true
  belongs_to :coupon, optional: true
  belongs_to :vendor, optional: true
  belongs_to :checkout_session, optional: true
  has_many :order_items, dependent: :destroy
  has_many :reviews, dependent: :nullify
  has_many :support_tickets, dependent: :nullify

  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :all_blank

  STATUSES = %w[pending confirmed processing shipped delivered cancelled].freeze

  SHIPPING_FREE_THRESHOLD = 999
  SHIPPING_FLAT_FEE = 99
  TAX_RATE = 0.18 # Legacy fallback; prefer HSN-based calculation
  DEFAULT_JEWELLERY_GST_RATE = 3.0
  PAYMENT_STATUSES = %w[pending paid failed refunded].freeze
  PAYMENT_METHODS = %w[cod razorpay].freeze
  REFUND_STATUSES = %w[not_refunded initiated paid failed].freeze
  CANCELLATION_REASONS = [
    "Changed my mind",
    "Found a better price elsewhere",
    "Ordered by mistake",
    "Delivery time is too long",
    "Want to change shipping address",
    "Want to change items in order",
    "Product quality issue",
    "Received damaged product",
    "Wrong item received",
    "Payment issue",
    "Other"
  ].freeze

  validates :order_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :payment_status, presence: true, inclusion: { in: PAYMENT_STATUSES }
  validates :payment_method, presence: true, inclusion: { in: PAYMENT_METHODS }

  validates :shipper_name, :shipping_carrier, :tracking_number, presence: true, if: :shipped?

  before_validation :generate_order_number, if: -> { order_number.blank? }
  before_save :ensure_address_snapshots

  # ── Address getters ──
  # Return an AddressSnapshot (preferred) or fall back to the Address record
  # for legacy orders that haven't been backfilled yet.

  def shipping_address
    if shipping_address_snapshot.present?
      AddressSnapshot.new(shipping_address_snapshot)
    elsif shipping_address_id.present?
      Address.unscoped.find_by(id: shipping_address_id)
    end
  end

  def billing_address
    if billing_address_snapshot.present?
      AddressSnapshot.new(billing_address_snapshot)
    elsif billing_address_id.present?
      Address.unscoped.find_by(id: billing_address_id)
    end
  end

  # ── Address setters ──
  # Accept an Address object, store the ID as a historical reference
  # and snapshot the data so the order is self-contained.

  def shipping_address=(address)
    return unless address.is_a?(Address)
    self.shipping_address_id = address.id
    self.shipping_address_snapshot = address_to_snapshot(address)
  end

  def billing_address=(address)
    return unless address.is_a?(Address)
    self.billing_address_id = address.id
    self.billing_address_snapshot = address_to_snapshot(address)
  end

  # Use order_number in storefront URLs instead of numeric ID
  def to_param
    order_number
  end

  scope :active, -> { where.not(status: "cancelled") }
  scope :draft, -> { where(is_draft: true) }
  scope :placed, -> { where(is_draft: false).where.not(placed_at: nil) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_vendor, ->(vendor) { where(vendor_id: vendor.id) if vendor }

  # Payout scopes
  scope :ready_for_payout, -> { where(status: "delivered", payment_status: "paid", payout_status: "pending") }
  scope :payout_pending, -> { where(payout_status: "pending") }
  scope :payout_requested, -> { where(payout_status: "requested") }
  scope :payout_paid, -> { where(payout_status: "paid") }

  has_many :vendor_payout_orders, dependent: :nullify
  has_many :vendor_payouts, through: :vendor_payout_orders
  has_many :payment_logs, dependent: :nullify

  # Razorpay scopes
  scope :razorpay_pending, -> { where(payment_method: "razorpay", payment_status: "pending") }
  scope :razorpay_failed, -> { where(payment_method: "razorpay", payment_status: "failed") }

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
        status: "confirmed"
      )
    end
    true
  rescue => e
    errors.add(:base, e.message)
    false
  end

  def confirm!
    update!(status: "confirmed")
  end

  def process!
    update!(status: "processing")
  end

  def ship!
    assign_attributes(status: "shipped", shipped_at: Time.current)
    save!
  end

  def deliver!
    transaction do
      update!(status: "delivered", delivered_at: Time.current, payment_status: "paid")
      calculate_vendor_fees!
    end
  end

  def can_rollback?
    # Cannot rollback cancelled orders
    return false if cancelled?

    # Cannot rollback confirmed orders if paid online (to prevent payment issues)
    if confirmed? && razorpay? && paid?
      errors.add(:status, "cannot be rolled back - online payment already processed")
      return false
    end

    %w[confirmed processing shipped delivered].include?(status)
  end

  def rollback!
    unless can_rollback?
      errors.add(:status, "cannot be rolled back from this state")
      raise ActiveRecord::RecordInvalid.new(self)
    end

    case status
    when "confirmed"
      update!(status: "pending")
    when "processing"
      update!(status: "confirmed")
    when "shipped"
      update!(status: "processing", shipped_at: nil)
    when "delivered"
      update!(status: "shipped", delivered_at: nil)
    end
  end

  def cancel!(reason: nil)
    return false if shipped? || delivered? || cancelled?

    transaction do
      # Restore stock
      order_items.each do |item|
        item.product_variant&.increment_stock!(item.quantity)
      end

      # Decrement coupon usage
      coupon&.decrement_usage!

      update!(status: "cancelled", cancelled_at: Time.current, cancellation_reason: reason)
    end
    true
  end

  def pending?
    status == "pending"
  end

  def confirmed?
    status == "confirmed"
  end

  def processing?
    status == "processing"
  end

  def shipped?
    status == "shipped"
  end

  def delivered?
    status == "delivered"
  end

  def cancelled?
    status == "cancelled"
  end

  def can_cancel?
    !shipped? && !delivered? && !cancelled?
  end

  def can_review?
    delivered?
  end

  def calculate_totals!
    self.subtotal = order_items.sum(&:total_price)
    self.discount_amount = coupon&.calculate_discount(subtotal) || 0

    discounted_subtotal = subtotal - discount_amount
    self.shipping_amount = self.class.calculate_shipping_amount(discounted_subtotal)

    # Calculate detailed tax breakdown
    calculate_detailed_tax!(discounted_subtotal)

    self.total_amount = subtotal - discount_amount + shipping_amount + tax_amount
  end

  def calculate_detailed_tax!(discounted_subtotal)
    return if subtotal.to_f <= 0 || discounted_subtotal <= 0

    ratio = discounted_subtotal.to_f / subtotal.to_f

    # Calculate per-item taxes and build breakdown
    item_taxes = []
    total_tax = 0

    order_items.each do |item|
      rate = item.product_variant&.product&.hsn_code&.gst_rate || DEFAULT_JEWELLERY_GST_RATE
      item_tax = (item.total_price.to_f * rate / 100.0 * ratio).round(2)

      item_taxes << {
        item_name: item.product_name,
        variant_name: item.variant_name,
        quantity: item.quantity,
        unit_price: item.unit_price,
        hsn_code: item.product_variant&.product&.hsn_code&.code || "7117",
        tax_rate: rate,
        taxable_amount: (item.total_price.to_f * ratio).round(2),
        tax_amount: item_tax,
        gst_type: rate <= 5 ? "IGST" : "CGST + SGST"
      }

      total_tax += item_tax
    end

    # Group taxes by rate for summary
    tax_summary = item_taxes.group_by { |item| item[:tax_rate] }.map do |rate, items|
      {
        rate: rate,
        total_taxable: items.sum { |i| i[:taxable_amount] }.round(2),
        total_tax: items.sum { |i| i[:tax_amount] }.round(2),
        item_count: items.count
      }
    end.sort_by { |s| -s[:rate] }

    self.tax_amount = total_tax.round(2)

    # Store detailed breakdown
    self.tax_breakdown = {
      summary: tax_summary,
      items: item_taxes,
      total_taxable_amount: item_taxes.sum { |i| i[:taxable_amount] }.round(2),
      total_tax_amount: total_tax.round(2),
      discount_applied: discount_amount,
      calculated_at: Time.current.iso8601
    }
  end

  def self.calculate_shipping_amount(discounted_subtotal)
    amount = discounted_subtotal.to_f
    return 0 if amount >= SHIPPING_FREE_THRESHOLD
    SHIPPING_FLAT_FEE
  end

  # Legacy class method kept for backward compatibility
  def self.calculate_tax_amount(taxable_amount)
    (taxable_amount.to_f * TAX_RATE).round(2)
  end

  # Per-item HSN-based tax calculation
  def calculate_hsn_tax(discounted_subtotal)
    return 0 if subtotal.to_f <= 0 || discounted_subtotal <= 0

    total_tax = order_items.sum do |item|
      rate = item.product_variant&.product&.hsn_code&.gst_rate || DEFAULT_JEWELLERY_GST_RATE
      (item.total_price.to_f * rate / 100.0)
    end

    # Adjust proportionally for discount
    ratio = discounted_subtotal.to_f / subtotal.to_f
    (total_tax * ratio).round(2)
  end

  def items_count
    order_items.sum(:quantity)
  end

  # Fee calculation and vendor earnings
  def calculate_vendor_fees!
    return unless delivered? && payment_status == "paid" && payout_status == "pending"

    config = PlatformFeeConfig.current
    fees = config.calculate_fees(total_amount)

    update!(
      platform_fee_amount: fees[:platform_fee],
      gateway_fee_amount: fees[:gateway_fee],
      gateway_gst_amount: fees[:gateway_gst],
      vendor_earnings: fees[:vendor_earnings]
    )
  end

  def ready_for_payout?
    delivered? && payment_status == "paid" && payout_status == "pending"
  end

  def calculate_fee_breakdown!
    config = PlatformFeeConfig.current
    fees = config.calculate_fees(total_amount)

    # Calculate payment gateway fees breakdown
    gateway_fee_details = {
      base_gateway_fee: fees[:gateway_fee],
      gst_on_gateway_fee: fees[:gateway_gst],
      gst_rate: config.gateway_gst_percent,
      gateway_rate: config.gateway_fee_percent
    }

    # Platform fee details
    platform_fee_details = {
      commission_rate: config.platform_commission_percent,
      commission_amount: fees[:platform_fee],
      commission_type: "Percentage on order value"
    }

    self.fee_breakdown = {
      platform_fee: platform_fee_details,
      gateway_fee: gateway_fee_details,
      total_deductions: fees[:total_fees],
      net_amount: fees[:vendor_earnings],
      platform_name: "Noralooks",
      payment_provider: "Razorpay",
      calculated_at: Time.current.iso8601
    }
  end

  def fee_breakdown_display
    return fee_breakdown if fee_breakdown.present?
    calculate_fee_breakdown! if delivered? && payment_status == "paid"
    fee_breakdown
  end

  def tax_breakdown_display
    return tax_breakdown if tax_breakdown.present?
    recalculate_tax_breakdown if tax_breakdown.blank? && subtotal.to_f > 0
    tax_breakdown
  end

  def recalculate_tax_breakdown
    discounted_subtotal = subtotal.to_f - discount_amount.to_f
    calculate_detailed_tax!(discounted_subtotal) if discounted_subtotal > 0
  end

  def full_pricing_breakdown
    {
      subtotal: subtotal,
      discount: discount_amount,
      shipping: shipping_amount,
      tax: tax_breakdown_display,
      fees: fee_breakdown_display,
      total: total_amount,
      payment_method: payment_method,
      payment_status: payment_status
    }
  end

  # Helper methods for displaying breakdown
  def tax_rate_display
    return "0%" if tax_breakdown.blank? || tax_breakdown["summary"].blank?

    rates = tax_breakdown["summary"].map { |s| "#{s['rate']}%" }.uniq
    rates.join(", ")
  end

  def gateway_fee_display
    return nil unless payment_method == "razorpay"

    config = PlatformFeeConfig.current
    "#{config.gateway_fee_percent}% + #{config.gateway_gst_percent}% GST"
  end

  # Razorpay Integration Methods
  def create_razorpay_order!
    return false unless payment_method == "razorpay" && payment_status == "pending"

    razorpay_order = Razorpay::Order.create(
      amount: (total_amount * 100).to_i, # Razorpay expects paise
      currency: "INR",
      receipt: order_number,
      notes: {
        order_id: id,
        vendor_id: vendor_id,
        customer_email: customer&.email,
        order_number: order_number
      }
    )

    update!(razorpay_order_id: razorpay_order.id)
    log_payment_event!("payment.initiated", {}, razorpay_order.attributes)

    razorpay_order
  rescue => e
    log_payment_event!("payment.initiated", {}, {}, "failed", e.message)
    raise
  end

  def verify_razorpay_payment!(payment_id, signature)
    # Support both flat and nested credential structures
    creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
            Rails.application.credentials.dig(:razorpay)

    key_secret = creds&.dig(:key_secret)

    if key_secret.blank?
      Rails.logger.error "[Razorpay] Key secret not configured"
      return false
    end

    generated_signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      key_secret,
      "#{razorpay_order_id}|#{payment_id}"
    )

    if ActiveSupport::SecurityUtils.secure_compare(generated_signature, signature)
      transaction do
        update!(
          razorpay_payment_id: payment_id,
          payment_signature: signature,
          payment_status: "paid"
        )
        place!
      end
      log_payment_event!("payment.captured", { payment_id: payment_id, signature: signature })
      true
    else
      log_payment_event!("payment.verification_failed", { payment_id: payment_id, signature: signature }, {}, "failed", "Signature mismatch")
      false
    end
  end

  def mark_payment_failed!(error_message = nil)
    increment!(:payment_attempts)
    update!(
      payment_status: "failed",
      payment_failed_at: Time.current,
      payment_error_message: error_message
    )
    log_payment_event!("payment.failed", {}, {}, "failed", error_message)
  end

  def can_retry_payment?
    payment_method == "razorpay" && payment_status == "failed" && payment_attempts < 3
  end

  def razorpay?
    payment_method == "razorpay"
  end

  def cod?
    payment_method == "cod"
  end

  def paid?
    payment_status == "paid"
  end

  # Refund methods
  def refundable?
    (cancelled? || status == "delivered") &&
    razorpay? &&
    paid? &&
    !refunded? &&
    refund_status != "failed"
  end

  def refunded?
    payment_status == "refunded" || refund_status == "paid"
  end

  def refund_initiated?
    refund_status == "initiated"
  end

  def eligible_for_refund_initiation?
    cancelled? && razorpay? && paid? && refund_status == "not_refunded"
  end

  def eligible_for_mark_refund_paid?
    refund_status == "initiated"
  end

  def initiate_refund!(amount: nil, transaction_id: nil, remarks: nil, processed_by: nil)
    return false unless eligible_for_refund_initiation?

    refund_amount = amount || total_amount

    update!(
      refund_status: "initiated",
      refund_amount: refund_amount,
      refund_transaction_id: transaction_id,
      refund_remarks: remarks,
      refund_initiated_at: Time.current,
      refund_processed_by: processed_by
    )
    true
  rescue => e
    errors.add(:base, "Failed to initiate refund: #{e.message}")
    false
  end

  def mark_refund_paid!(transaction_id: nil, remarks: nil)
    return false unless eligible_for_mark_refund_paid?

    transaction do
      update!(
        refund_status: "paid",
        payment_status: "refunded",
        refund_paid_at: Time.current,
        refund_transaction_id: transaction_id || self.refund_transaction_id,
        refund_remarks: remarks || self.refund_remarks
      )
    end
    true
  rescue => e
    errors.add(:base, "Failed to mark refund as paid: #{e.message}")
    false
  end

  def mark_refund_failed!(error_message = nil)
    return false unless refund_initiated?

    update!(
      refund_status: "failed",
      refund_remarks: error_message
    )
    true
  rescue => e
    errors.add(:base, "Failed to mark refund as failed: #{e.message}")
    false
  end

  private

  def log_payment_event!(event_type, request_data = {}, response_data = {}, status = "success", error_message = nil)
    PaymentLog.create!(
      order: self,
      event_type: event_type,
      request_data: request_data,
      response_data: response_data,
      status: status,
      error_message: error_message
    )
  end

  def generate_order_number
    loop do
      self.order_number = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless Order.exists?(order_number: order_number)
    end
  end

  # When address IDs are set directly (e.g. admin draft orders), automatically
  # snapshot the address data so the order is always self-contained.
  def ensure_address_snapshots
    %i[shipping billing].each do |type|
      id_attr       = :"#{type}_address_id"
      snapshot_attr = :"#{type}_address_snapshot"

      next unless send(id_attr).present?

      # Snapshot if there's no snapshot yet, or the ID changed without
      # the setter already updating the snapshot.
      needs_snapshot = send(snapshot_attr).blank? ||
        (will_save_change_to_attribute?(id_attr) && !will_save_change_to_attribute?(snapshot_attr))

      if needs_snapshot && (addr = Address.unscoped.find_by(id: send(id_attr)))
        send(:"#{snapshot_attr}=", address_to_snapshot(addr))
      end
    end
  end

  def address_to_snapshot(address)
    {
      first_name:     address.first_name,
      last_name:      address.last_name,
      phone:          address.phone,
      street_address: address.street_address,
      apartment:      address.apartment,
      city:           address.city,
      state:          address.state,
      postal_code:    address.postal_code,
      country:        address.country
    }
  end
end
