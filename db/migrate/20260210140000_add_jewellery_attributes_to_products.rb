class AddJewelleryAttributesToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :base_material, :string
    add_column :products, :plating, :string
    add_column :products, :gemstone, :string
    add_column :products, :occasion, :string
    add_column :products, :ideal_for, :string
    add_column :products, :country_of_origin, :string, default: "India"

    add_index :products, :base_material
    add_index :products, :plating
    add_index :products, :gemstone
    add_index :products, :occasion
    add_index :products, :ideal_for
  end
end
