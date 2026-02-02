class AdminUser < ApplicationRecord
  include SoftDeletable
  has_secure_password

  has_many :ticket_messages, as: :sender, dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }

  before_save :downcase_email

  scope :active, -> { where(active: true) }

  def self.authenticate(email, password)
    admin = find_by(email: email.downcase)
    admin&.authenticate(password)
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
