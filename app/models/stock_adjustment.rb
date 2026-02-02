class StockAdjustment < ApplicationRecord
  belongs_to :product_variant
  belongs_to :adjusted_by, polymorphic: true, optional: true

  REASONS = {
    'restock' => 'Restock / Purchase',
    'sale' => 'Sale',
    'return' => 'Customer Return',
    'damage' => 'Damaged Goods',
    'loss' => 'Lost / Stolen',
    'correction' => 'Inventory Correction',
    'initial' => 'Initial Stock',
    'transfer' => 'Transfer'
  }.freeze

  validates :quantity_change, presence: true
  validates :quantity_before, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_after, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reason, presence: true, inclusion: { in: REASONS.keys }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_reason, ->(reason) { where(reason: reason) if reason.present? }
  scope :increases, -> { where('quantity_change > 0') }
  scope :decreases, -> { where('quantity_change < 0') }

  delegate :product, to: :product_variant

  def reason_label
    REASONS[reason] || reason.titleize
  end

  def increase?
    quantity_change > 0
  end

  def decrease?
    quantity_change < 0
  end

  def adjuster_name
    return 'System' unless adjusted_by
    adjusted_by.respond_to?(:full_name) ? adjusted_by.full_name : adjusted_by.name
  end
end
