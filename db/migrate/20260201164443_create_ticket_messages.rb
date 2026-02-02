class CreateTicketMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_messages do |t|
      t.references :support_ticket, null: false, foreign_key: true
      t.string :sender_type, null: false # Customer, Admin
      t.integer :sender_id, null: false
      t.text :body, null: false

      t.timestamps
    end
    add_index :ticket_messages, [:sender_type, :sender_id]
  end
end
