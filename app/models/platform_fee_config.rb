class PlatformFeeConfig < ApplicationRecord
  validates :platform_commission_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :gateway_fee_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :gateway_gst_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :minimum_payout_amount, presence: true, numericality: { greater_than: 0 }
  validates :maximum_payout_amount, presence: true, numericality: { greater_than: 0 }

  after_initialize :set_defaults, if: :new_record?

  def self.current
    first || create!
  end

  def calculate_fees(order_total)
    platform_fee = (order_total * platform_commission_percent / 100).round(2)
    gateway_fee = (order_total * gateway_fee_percent / 100).round(2)
    gateway_gst = (gateway_fee * gateway_gst_percent / 100).round(2)
    total_fees = platform_fee + gateway_fee + gateway_gst
    vendor_earnings = order_total - total_fees

    {
      platform_fee: platform_fee,
      gateway_fee: gateway_fee,
      gateway_gst: gateway_gst,
      total_fees: total_fees,
      vendor_earnings: vendor_earnings
    }
  end

  private

  def set_defaults
    self.platform_commission_percent ||= 10.0
    self.gateway_fee_percent ||= 2.0
    self.gateway_gst_percent ||= 18.0
    self.minimum_payout_amount ||= 500.0
    self.maximum_payout_amount ||= 50000.0
    self.absorb_fees = true if absorb_fees.nil?
  end
end
