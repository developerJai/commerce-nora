class AdminUser < ApplicationRecord
  include SoftDeletable
  has_secure_password

  ROLES = %w[admin vendor].freeze

  belongs_to :vendor, optional: true
  has_many :ticket_messages, as: :sender, dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  validates :vendor_id, presence: true, if: -> { role == 'vendor' }

  before_save :downcase_email

  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: 'admin') }
  scope :vendors, -> { where(role: 'vendor') }

  def self.authenticate(email, password, role: nil)
    scope = role ? where(role: role) : all
    admin = scope.find_by(email: email.downcase)
    admin&.authenticate(password)
  end

  def admin?
    role == 'admin'
  end

  def vendor?
    role == 'vendor'
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
