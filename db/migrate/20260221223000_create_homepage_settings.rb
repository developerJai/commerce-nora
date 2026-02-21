class CreateHomepageSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :homepage_settings do |t|
      # Flash Sale Settings
      t.boolean :flash_sale_enabled, default: true, null: false
      t.string :flash_sale_title, default: "Flash Sale"
      t.string :flash_sale_heading, default: "Up to 50% OFF"
      t.text :flash_sale_description, default: "Limited time offer on bestselling artificial jewellery. Shop now before it is gone!"
      t.integer :flash_sale_discount, default: 50
      t.string :flash_sale_cta_text, default: "Shop Now"
      t.string :flash_sale_cta_link, default: "/products"
      t.datetime :flash_sale_ends_at

      # Promotional Banner Settings
      t.boolean :promo_banner_enabled, default: true, null: false
      t.string :promo_banner_title, default: "First Order Offer"
      t.string :promo_banner_heading, default: "Get 10% Off"
      t.string :promo_banner_code, default: "WELCOME10"
      t.string :promo_banner_cta_text, default: "Shop Now"
      t.string :promo_banner_cta_link, default: "/products"

      # Bundle Deals Settings
      t.boolean :bundle_deals_enabled, default: true, null: false
      t.string :bundle_deals_title, default: "Bundle and Save"
      t.string :bundle_deals_heading, default: "Complete Your Look"
      t.text :bundle_deals_description, default: "Buy matching sets and save big! Perfect combinations for weddings and festivals."

      # Hero Section Settings
      t.string :hero_tagline, default: "Timeless Elegance"
      t.string :hero_subtitle, default: "Exquisite artificial jewellery, thoughtful gifts, and beautiful ethnic wear for every occasion"
      t.string :search_placeholder_prefix, default: "Search"

      t.timestamps
    end
  end
end
