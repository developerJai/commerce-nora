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
      [first_name, last_name].compact_blank.join(" ")
    end

    def full_address
      [street_address, apartment, city, state, postal_code, country].compact_blank.join(", ")
    end

    def one_line
      "#{full_name}, #{full_address}"
    end
  end

  # ── Associations ──
  belongs_to :customer, optional: true
  belongs_to :coupon, optional: true
  belongs_to :vendor, optional: true
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
  PAYMENT_METHODS = %w[cod].freeze
  CANCELLATION_REASONS = [
    'Changed my mind',
    'Found a better price elsewhere',
    'Ordered by mistake',
    'Delivery time is too long',
    'Want to change shipping address',
    'Want to change items in order',
    'Other'
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

  scope :active, -> { where.not(status: 'cancelled') }
  scope :draft, -> { where(is_draft: true) }
  scope :placed, -> { where(is_draft: false).where.not(placed_at: nil) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_vendor, ->(vendor) { where(vendor_id: vendor.id) if vendor }

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
    assign_attributes(status: 'shipped', shipped_at: Time.current)
    save!
  end

  def deliver!
    update!(status: 'delivered', delivered_at: Time.current, payment_status: 'paid')
  end

  def rollback!
    case status
    when 'confirmed'
      update!(status: 'pending')
    when 'processing'
      update!(status: 'confirmed')
    when 'shipped'
      update!(status: 'processing', shipped_at: nil)
    when 'delivered'
      update!(status: 'shipped', delivered_at: nil)
    else
      errors.add(:status, 'cannot be rolled back')
      raise ActiveRecord::RecordInvalid.new(self)
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

      update!(status: 'cancelled', cancelled_at: Time.current, cancellation_reason: reason)
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
    self.tax_amount = calculate_hsn_tax(discounted_subtotal)

    self.total_amount = subtotal - discount_amount + shipping_amount + tax_amount
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

  private

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
