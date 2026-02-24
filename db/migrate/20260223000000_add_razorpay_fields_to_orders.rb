class AddRazorpayFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :razorpay_order_id, :string
    add_column :orders, :razorpay_payment_id, :string
    add_column :orders, :payment_signature, :string
    add_column :orders, :payment_attempts, :integer, default: 0
    add_column :orders, :payment_failed_at, :datetime
    add_column :orders, :payment_error_message, :text

    add_index :orders, :razorpay_order_id, unique: true
    add_index :orders, :razorpay_payment_id
  end
end
