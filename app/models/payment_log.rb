class PaymentLog < ApplicationRecord
  belongs_to :order

  validates :event_type, presence: true
  validates :status, inclusion: { in: %w[success failed] }

  scope :recent, -> { order(created_at: :desc) }
  scope :failed, -> { where(status: "failed") }
  scope :for_order, ->(order_id) { where(order_id: order_id) }

  def success?
    status == "success"
  end

  def failed?
    status == "failed"
  end
end
