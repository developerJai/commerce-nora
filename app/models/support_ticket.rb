class SupportTicket < ApplicationRecord
  include SoftDeletable
  belongs_to :customer, optional: true
  belongs_to :order, optional: true
  belongs_to :vendor, optional: true
  has_many :ticket_messages, dependent: :destroy

  STATUSES = %w[open in_progress resolved closed].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  validates :ticket_number, presence: true, uniqueness: true
  validates :subject, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validate :must_have_customer_or_vendor

  def vendor_ticket?
    vendor_id.present? && customer_id.blank?
  end

  def customer_ticket?
    customer_id.present?
  end

  before_validation :generate_ticket_number, if: -> { ticket_number.blank? }

  # Use ticket_number in storefront URLs instead of numeric ID
  def to_param
    ticket_number
  end

  scope :open_tickets, -> { where(status: %w[open in_progress]) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_vendor, ->(vendor) {
    if vendor
      left_joins(:order).where("orders.vendor_id = :vid OR support_tickets.vendor_id = :vid", vid: vendor.id)
    end
  }

  scope :unread_for_customer, -> {
    where(last_message_sender_type: 'AdminUser')
      .where("customer_last_seen_at IS NULL OR last_message_at IS NULL OR customer_last_seen_at < last_message_at")
  }

  scope :unread_for_admin, -> {
    where(last_message_sender_type: 'Customer')
      .where("admin_last_seen_at IS NULL OR last_message_at IS NULL OR admin_last_seen_at < last_message_at")
  }

  def open?
    status == 'open'
  end

  def in_progress?
    status == 'in_progress'
  end

  def resolved?
    status == 'resolved'
  end

  def closed?
    status == 'closed'
  end

  def can_reply?
    !closed?
  end

  def mark_in_progress!
    update!(status: 'in_progress')
  end

  def resolve!
    update!(status: 'resolved', resolved_at: Time.current)
  end

  def close!
    update!(status: 'closed')
  end

  def reopen!
    update!(status: 'open', resolved_at: nil)
  end

  def add_message(sender:, body:)
    transaction do
      message = ticket_messages.create!(
        sender_type: sender.class.name,
        sender_id: sender.id,
        body: body
      )

      update_columns(
        last_message_at: message.created_at,
        last_message_sender_type: message.sender_type,
        updated_at: Time.current
      )

      now = Time.current
      if message.sender_type == 'Customer'
        update_columns(customer_last_seen_at: now)
      elsif message.sender_type == 'AdminUser'
        update_columns(admin_last_seen_at: now)
      end

      message
    end
  end

  def unread_for_customer?
    last_message_sender_type == 'AdminUser' && last_message_at.present? && (customer_last_seen_at.nil? || customer_last_seen_at < last_message_at)
  end

  def unread_for_admin?
    last_message_sender_type == 'Customer' && last_message_at.present? && (admin_last_seen_at.nil? || admin_last_seen_at < last_message_at)
  end

  private

  def generate_ticket_number
    loop do
      self.ticket_number = "TKT-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
      break unless SupportTicket.exists?(ticket_number: ticket_number)
    end
  end

  def must_have_customer_or_vendor
    if customer_id.blank? && vendor_id.blank?
      errors.add(:base, "Ticket must belong to either a customer or a vendor")
    end
  end
end
