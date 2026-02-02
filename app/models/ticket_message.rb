class TicketMessage < ApplicationRecord
  belongs_to :support_ticket
  belongs_to :sender, polymorphic: true

  validates :body, presence: true
  validates :sender_type, presence: true, inclusion: { in: %w[Customer AdminUser] }
  validates :sender_id, presence: true

  scope :recent, -> { order(created_at: :asc) }

  after_create :update_ticket_status

  def from_customer?
    sender_type == 'Customer'
  end

  def from_admin?
    sender_type == 'AdminUser'
  end

  def sender_name
    sender&.respond_to?(:full_name) ? sender.full_name : sender&.name || "Unknown"
  end

  private

  def update_ticket_status
    support_ticket.mark_in_progress! if from_admin? && support_ticket.open?
  end
end
