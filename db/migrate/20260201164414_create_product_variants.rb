class CreateProductVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sku, null: false
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.decimal :compare_at_price, precision: 10, scale: 2
      t.integer :stock_quantity, default: 0, null: false
      t.decimal :weight, precision: 8, scale: 2
      t.boolean :active, default: true, null: false
      t.integer :position, default: 0

      t.timestamps
    end
    add_index :product_variants, :sku, unique: true
    add_index :product_variants, :active
  end
end
