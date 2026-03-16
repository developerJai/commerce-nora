class AddProductVariantToWishlists < ActiveRecord::Migration[8.0]
  def change
    add_reference :wishlists, :product_variant, foreign_key: { to_table: :product_variants }
    
    # Update uniqueness index to include variant (allow same product with different variants)
    remove_index :wishlists, [:customer_id, :product_id]
    add_index :wishlists, [:customer_id, :product_id, :product_variant_id], 
              unique: true, 
              name: 'index_wishlists_on_customer_product_and_variant'
  end
end
