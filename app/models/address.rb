class Address < ApplicationRecord
  include SoftDeletable

  belongs_to :customer

  ADDRESS_TYPES = %w[shipping billing].freeze

  validates :first_name, :last_name, :street_address, :city, :state, :postal_code, :country, presence: true
  validates :token, presence: true, uniqueness: true

  scope :shipping, -> { where(address_type: 'shipping') }
  scope :billing, -> { where(address_type: 'billing') }
  scope :default_first, -> { order(is_default: :desc, created_at: :desc) }

  before_validation :generate_token, if: -> { token.blank? }
  before_validation :set_default_address_type
  before_save :ensure_single_default

  # Use token in storefront URLs instead of numeric ID
  def to_param
    token
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def full_phone
    return phone if country_code.blank?
    "#{country_code} #{phone}"
  end

  def full_address
    [street_address, apartment, city, state, postal_code, country].compact_blank.join(", ")
  end

  def one_line
    "#{full_name}, #{full_address}"
  end

  private

  def generate_token
    loop do
      self.token = SecureRandom.urlsafe_base64(8)
      break unless Address.unscoped.exists?(token: token)
    end
  end

  def set_default_address_type
    self.address_type ||= 'shipping'
  end

  def ensure_single_default
    if is_default?
      customer.addresses.where.not(id: id).update_all(is_default: false)
    end
  end
end
