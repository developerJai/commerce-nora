class AddDetailedTaxFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    # Store JSON breakdown of all taxes and fees
    add_column :orders, :tax_breakdown, :jsonb, default: {}
    add_column :orders, :fee_breakdown, :jsonb, default: {}

    # Store individual order item tax details
    add_column :order_items, :tax_rate, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :order_items, :tax_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :order_items, :tax_details, :jsonb, default: {}

    # Add index for faster queries
    add_index :orders, :tax_breakdown, using: :gin
  end
end
