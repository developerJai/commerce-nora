class CreateStockAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_adjustments do |t|
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity_change, null: false
      t.integer :quantity_before, null: false
      t.integer :quantity_after, null: false
      t.string :reason, null: false
      t.text :notes
      t.references :adjusted_by, polymorphic: true

      t.timestamps
    end

    add_index :stock_adjustments, :reason
    add_index :stock_adjustments, :created_at
  end
end
