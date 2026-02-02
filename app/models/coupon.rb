class Coupon < ApplicationRecord
  include SoftDeletable
  has_many :orders, dependent: :nullify

  DISCOUNT_TYPES = %w[percentage fixed].freeze

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :discount_type, presence: true, inclusion: { in: DISCOUNT_TYPES }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :minimum_order_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :upcase_code

  scope :active, -> { where(active: true) }
  scope :valid_now, -> {
    now = Time.current
    where("(starts_at IS NULL OR starts_at <= ?) AND (expires_at IS NULL OR expires_at >= ?)", now, now)
  }
  scope :available, -> { active.valid_now.where("usage_limit IS NULL OR usage_count < usage_limit") }

  def self.find_by_code(code)
    find_by(code: code.upcase)
  end

  def valid_for_use?
    active? && within_date_range? && within_usage_limit?
  end

  def within_date_range?
    now = Time.current
    (starts_at.nil? || starts_at <= now) && (expires_at.nil? || expires_at >= now)
  end

  def within_usage_limit?
    usage_limit.nil? || usage_count < usage_limit
  end

  def applicable_to?(subtotal)
    minimum_order_amount.nil? || subtotal >= minimum_order_amount
  end

  def calculate_discount(subtotal)
    return 0 unless valid_for_use? && applicable_to?(subtotal)

    discount = if percentage?
      subtotal * (discount_value / 100)
    else
      discount_value
    end

    # Apply maximum discount cap if set
    if maximum_discount.present? && discount > maximum_discount
      discount = maximum_discount
    end

    # Don't exceed subtotal
    [discount, subtotal].min.round(2)
  end

  def percentage?
    discount_type == 'percentage'
  end

  def fixed?
    discount_type == 'fixed'
  end

  def increment_usage!
    increment!(:usage_count)
  end

  def decrement_usage!
    decrement!(:usage_count) if usage_count > 0
  end

  def display_value
    if percentage?
      "#{discount_value}%"
    else
      "$#{discount_value}"
    end
  end

  private

  def upcase_code
    self.code = code.upcase
  end
end
