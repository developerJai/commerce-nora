class Address < ApplicationRecord
  belongs_to :customer

  ADDRESS_TYPES = %w[shipping billing].freeze

  validates :address_type, presence: true, inclusion: { in: ADDRESS_TYPES }
  validates :first_name, :last_name, :street_address, :city, :state, :postal_code, :country, presence: true

  scope :shipping, -> { where(address_type: 'shipping') }
  scope :billing, -> { where(address_type: 'billing') }
  scope :default_first, -> { order(is_default: :desc, created_at: :desc) }

  before_save :ensure_single_default

  def full_name
    "#{first_name} #{last_name}"
  end

  def full_address
    [street_address, apartment, city, state, postal_code, country].compact_blank.join(", ")
  end

  def one_line
    "#{full_name}, #{full_address}"
  end

  private

  def ensure_single_default
    if is_default?
      customer.addresses.where(address_type: address_type).where.not(id: id).update_all(is_default: false)
    end
  end
end
