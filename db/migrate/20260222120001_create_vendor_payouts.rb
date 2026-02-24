class CreateVendorPayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :vendor_payouts do |t|
      t.references :vendor, null: false, foreign_key: true
      t.decimal :total_amount, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :platform_fee_total, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :gateway_fee_total, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :gateway_gst_total, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :net_payout, precision: 12, scale: 2, default: 0.0, null: false
      t.string :status, default: 'pending', null: false # pending, approved, paid, rejected
      t.text :admin_notes
      t.string :transaction_reference
      t.datetime :paid_at
      t.datetime :approved_at
      t.datetime :rejected_at
      t.timestamps
    end

    add_index :vendor_payouts, :status
    add_index :vendor_payouts, [ :vendor_id, :status ]
  end
end
