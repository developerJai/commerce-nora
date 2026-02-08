class Vendor < ApplicationRecord
  include SoftDeletable

  has_many :admin_users, dependent: :nullify
  has_many :products, dependent: :nullify
  has_many :orders, dependent: :nullify
  has_many :support_tickets, dependent: :nullify

  validates :business_name, presence: true
  validates :contact_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  before_save :downcase_email

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(business_name: :asc) }

  def display_name
    business_name
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
