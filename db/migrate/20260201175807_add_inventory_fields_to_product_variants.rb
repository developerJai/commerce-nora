class AddInventoryFieldsToProductVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :product_variants, :reorder_point, :integer, default: 10
    add_column :product_variants, :reorder_quantity, :integer, default: 50
    add_column :product_variants, :track_inventory, :boolean, default: true
  end
end
