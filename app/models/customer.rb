class Customer < ApplicationRecord
  include SoftDeletable
  has_secure_password

  has_many :addresses, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :reviews, dependent: :nullify
  has_many :support_tickets, dependent: :destroy
  has_many :ticket_messages, as: :sender, dependent: :nullify
  has_many :wishlist_items, dependent: :destroy, class_name: 'Wishlist'
  has_many :wished_products, through: :wishlist_items, source: :product

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :first_name, presence: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  validates :phone, format: { with: /\A[\d\s\-\(\)]+\z/, message: "must be a valid phone number" }, allow_blank: false, presence: true
  validates :country_code, format: { with: /\A\+\d{1,4}\z/, message: "must be a valid country code" }, allow_blank: false

  before_save :downcase_email
  validate :validate_phone_by_country, if: -> { phone.present? && country_code.present? }

  scope :active, -> { where(active: true) }
  scope :bots, -> { where(is_bot: true) }

  def self.authenticate(email, password)
    customer = active.find_by(email: email.downcase)
    customer&.authenticate(password)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def full_phone_number
    "#{country_code} #{phone}"
  end

  def validate_phone_by_country
    case country_code
    when '+91'
      # India: 10 digits (no leading 0)
      errors.add(:phone, "Indian phone numbers must be exactly 10 digits") unless phone.match?(/\A[6-9]\d{9}\z/)
    when '+1'
      # US/Canada: 10 digits
      errors.add(:phone, "US/Canada phone numbers must be exactly 10 digits") unless phone.match?(/\A\d{10}\z/)
    when '+44'
      # UK: 10-11 digits, no leading 0
      errors.add(:phone, "UK phone numbers must be 10-11 digits without leading 0") unless phone.match?(/\A[1-9]\d{9,10}\z/)
    else
      # Generic validation for other countries
      errors.add(:phone, "Phone number must be valid for your country") unless phone.match?(/\A[\d\s\-\(\)]+\z/)
    end
  end

  def active_cart
    carts.find_by(status: 'active') || carts.create!(token: SecureRandom.uuid)
  end

  def default_shipping_address
    addresses.find_by(address_type: 'shipping', is_default: true) ||
      addresses.find_by(address_type: 'shipping')
  end

  def default_billing_address
    addresses.find_by(address_type: 'billing', is_default: true) ||
      addresses.find_by(address_type: 'billing') ||
      default_shipping_address
  end

  def wishlist_count
    wishlist_items.count
  end

  def unread_support_tickets_count
    support_tickets.unread_for_customer.count
  end

  def product_in_wishlist?(product, variant_id: nil)
    if variant_id.present?
      wishlist_items.exists?(product_id: product.id, product_variant_id: variant_id)
    else
      wishlist_items.exists?(product_id: product.id)
    end
  end

  private

  def downcase_email
    self.email = email.to_s.downcase.presence
  end
end
