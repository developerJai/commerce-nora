class CreateSupportTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :support_tickets do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :order, foreign_key: true
      t.string :ticket_number, null: false
      t.string :subject, null: false
      t.string :status, default: 'open', null: false # open, in_progress, resolved, closed
      t.string :priority, default: 'normal', null: false # low, normal, high, urgent
      t.datetime :resolved_at

      t.timestamps
    end
    add_index :support_tickets, :ticket_number, unique: true
    add_index :support_tickets, :status
  end
end
