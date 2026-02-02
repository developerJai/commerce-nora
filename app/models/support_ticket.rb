class SupportTicket < ApplicationRecord
  include SoftDeletable
  belongs_to :customer
  belongs_to :order, optional: true
  has_many :ticket_messages, dependent: :destroy

  STATUSES = %w[open in_progress resolved closed].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  validates :ticket_number, presence: true, uniqueness: true
  validates :subject, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :priority, presence: true, inclusion: { in: PRIORITIES }

  before_validation :generate_ticket_number, if: -> { ticket_number.blank? }

  scope :open_tickets, -> { where(status: %w[open in_progress]) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :recent, -> { order(created_at: :desc) }

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
    ticket_messages.create!(
      sender_type: sender.class.name,
      sender_id: sender.id,
      body: body
    )
  end

  private

  def generate_ticket_number
    loop do
      self.ticket_number = "TKT-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
      break unless SupportTicket.exists?(ticket_number: ticket_number)
    end
  end
end
