class CreateBundleDeals < ActiveRecord::Migration[8.1]
  def change
    create_table :bundle_deals do |t|
      t.string :title, null: false
      t.text :description
      t.decimal :original_price, precision: 10, scale: 2, null: false
      t.decimal :discounted_price, precision: 10, scale: 2, null: false
      t.integer :discount_percentage, default: 0
      t.string :icon_emoji, default: "💍"
      t.string :cta_text, default: "Add to Cart"
      t.string :cta_link, default: "/products"
      t.integer :position, default: 0
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :bundle_deals, :active
    add_index :bundle_deals, :position
  end
end
