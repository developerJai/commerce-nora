class VendorPayoutOrder < ApplicationRecord
  belongs_to :vendor_payout
  belongs_to :order

  validates :order_id, uniqueness: { scope: :vendor_payout_id }
end
