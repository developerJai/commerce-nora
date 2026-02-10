class AddColorAndSizeToProductVariants < ActiveRecord::Migration[8.1]
  def change
    add_column :product_variants, :color, :string
    add_column :product_variants, :size, :string

    add_index :product_variants, :color
    add_index :product_variants, :size
  end
end
