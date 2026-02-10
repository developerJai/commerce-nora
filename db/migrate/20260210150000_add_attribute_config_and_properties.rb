class AddAttributeConfigAndProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :attribute_config, :jsonb, default: {}
    add_column :products, :properties, :jsonb, default: {}
    add_column :product_variants, :properties, :jsonb, default: {}
  end
end
