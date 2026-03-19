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
  validates :phone, format: { with: /\A\+[\d\s\-\(\)]+\z/, message: "must be a valid international phone number" }, allow_blank: false,presence: true

  before_save :downcase_email

  scope :active, -> { where(active: true) }

  def self.authenticate(email, password)
    customer = active.find_by(email: email.downcase)
    customer&.authenticate(password)
  end

  def full_name
    "#{first_name} #{last_name}"
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

  def product_in_wishlist?(product)
    wishlist_items.exists?(product_id: product.id)
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
