class CreateCheckoutSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :checkout_sessions do |t|
      t.string :batch_id
      t.string :razorpay_order_id
      t.decimal :total_amount
      t.references :customer, null: false, foreign_key: true
      t.string :status
      t.string :payment_method
      t.text :notes

      t.timestamps
    end
  end
end
