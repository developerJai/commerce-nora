class CreatePlatformFeeConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_fee_configs do |t|
      t.decimal :platform_commission_percent, precision: 5, scale: 2, default: 10.0, null: false
      t.decimal :gateway_fee_percent, precision: 5, scale: 2, default: 2.0, null: false
      t.decimal :gateway_gst_percent, precision: 5, scale: 2, default: 18.0, null: false
      t.decimal :minimum_payout_amount, precision: 10, scale: 2, default: 500.0, null: false
      t.decimal :maximum_payout_amount, precision: 10, scale: 2, default: 50000.0, null: false
      t.boolean :absorb_fees, default: true, null: false
      t.timestamps
    end
  end
end
