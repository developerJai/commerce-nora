class CreateCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.string :discount_type, null: false, default: 'percentage' # percentage, fixed
      t.decimal :discount_value, precision: 10, scale: 2, null: false, default: 0
      t.decimal :minimum_order_amount, precision: 10, scale: 2, default: 0
      t.decimal :maximum_discount, precision: 10, scale: 2
      t.integer :usage_limit
      t.integer :usage_count, default: 0, null: false
      t.datetime :starts_at
      t.datetime :expires_at
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :coupons, :code, unique: true
    add_index :coupons, :active
  end
end
