class AddRefundFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    # Refund tracking fields
    add_column :orders, :refund_status, :string, default: 'not_refunded' # not_refunded, initiated, paid, failed
    add_column :orders, :refund_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :orders, :refund_transaction_id, :string
    add_column :orders, :refund_remarks, :text
    add_column :orders, :refund_initiated_at, :datetime
    add_column :orders, :refund_paid_at, :datetime
    add_column :orders, :refund_processed_by, :bigint # admin user id

    # Index for refund queries
    add_index :orders, :refund_status
  end
end
