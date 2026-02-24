class CreateVendorPayoutOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :vendor_payout_orders do |t|
      t.references :vendor_payout, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.timestamps
    end

    add_index :vendor_payout_orders, [ :vendor_payout_id, :order_id ], unique: true
  end
end
