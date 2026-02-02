class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :customer, foreign_key: true
      t.string :order_number, null: false
      t.string :status, default: 'pending', null: false # pending, confirmed, processing, shipped, delivered, cancelled
      t.string :payment_status, default: 'pending', null: false # pending, paid, failed, refunded
      t.string :payment_method, default: 'cod', null: false # cod (cash on delivery)
      t.decimal :subtotal, precision: 10, scale: 2, default: 0, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0, null: false
      t.decimal :shipping_amount, precision: 10, scale: 2, default: 0, null: false
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0, null: false
      t.decimal :total_amount, precision: 10, scale: 2, default: 0, null: false
      t.references :shipping_address, foreign_key: { to_table: :addresses }
      t.references :billing_address, foreign_key: { to_table: :addresses }
      t.references :coupon, foreign_key: true
      t.text :notes
      t.text :admin_notes
      t.datetime :placed_at
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.datetime :cancelled_at
      t.boolean :is_draft, default: false, null: false

      t.timestamps
    end
    add_index :orders, :order_number, unique: true
    add_index :orders, :status
    add_index :orders, :is_draft
  end
end
