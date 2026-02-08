class HsnCode < ApplicationRecord
  has_many :products, dependent: :nullify

  validates :code, presence: true, uniqueness: true
  validates :description, presence: true
  validates :gst_rate, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:code) }

  def display_name
    "#{code} - #{description} (#{gst_rate}%)"
  end
end
