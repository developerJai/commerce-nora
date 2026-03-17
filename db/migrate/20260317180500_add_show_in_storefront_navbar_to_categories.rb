class AddShowInStorefrontNavbarToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :show_in_storefront_navbar, :boolean, default: false, null: false
    add_index :categories, :show_in_storefront_navbar
  end
end
