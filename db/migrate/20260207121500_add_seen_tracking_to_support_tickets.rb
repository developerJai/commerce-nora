class AddSeenTrackingToSupportTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :support_tickets, :last_message_at, :datetime
    add_column :support_tickets, :last_message_sender_type, :string
    add_column :support_tickets, :customer_last_seen_at, :datetime
    add_column :support_tickets, :admin_last_seen_at, :datetime

    add_index :support_tickets, :last_message_at
    add_index :support_tickets, :last_message_sender_type
    add_index :support_tickets, :customer_last_seen_at
    add_index :support_tickets, :admin_last_seen_at
  end
end
