class CreatePaymentLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_logs do |t|
      t.references :order, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :request_data, default: {}
      t.jsonb :response_data, default: {}
      t.string :status, default: 'success'
      t.text :error_message
      t.timestamps
    end

    add_index :payment_logs, [ :order_id, :event_type ]
    add_index :payment_logs, :created_at
  end
end
