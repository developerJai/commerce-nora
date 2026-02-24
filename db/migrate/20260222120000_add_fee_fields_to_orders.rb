class AddFeeFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :platform_fee_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :orders, :gateway_fee_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :orders, :gateway_gst_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :orders, :vendor_earnings, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :orders, :payout_status, :string, default: 'pending' # pending, requested, paid
    add_index :orders, :payout_status
  end
end
