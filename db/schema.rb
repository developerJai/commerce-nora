# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_21_225000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "address_type", default: "shipping", null: false
    t.string "apartment"
    t.string "city", null: false
    t.string "country", default: "US", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.datetime "deleted_at"
    t.string "first_name", null: false
    t.boolean "is_default", default: false, null: false
    t.string "last_name", null: false
    t.string "phone"
    t.string "postal_code", null: false
    t.string "state", null: false
    t.string "street_address", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "address_type"], name: "index_addresses_on_customer_id_and_address_type"
    t.index ["customer_id"], name: "index_addresses_on_customer_id"
    t.index ["deleted_at"], name: "index_addresses_on_deleted_at"
    t.index ["token"], name: "index_addresses_on_token", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", null: false
    t.datetime "last_login_at"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "admin", null: false
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["deleted_at"], name: "index_admin_users_on_deleted_at"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["role"], name: "index_admin_users_on_role"
    t.index ["vendor_id"], name: "index_admin_users_on_vendor_id"
  end

  create_table "banners", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "ends_at"
    t.string "image_url"
    t.string "link_url"
    t.integer "position", default: 0
    t.datetime "starts_at"
    t.string "subtitle"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_banners_on_active"
    t.index ["deleted_at"], name: "index_banners_on_deleted_at"
    t.index ["position"], name: "index_banners_on_position"
  end

  create_table "bundle_deal_items", force: :cascade do |t|
    t.bigint "bundle_deal_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["bundle_deal_id", "product_id"], name: "index_bundle_deal_items_on_bundle_deal_id_and_product_id", unique: true
    t.index ["bundle_deal_id"], name: "index_bundle_deal_items_on_bundle_deal_id"
    t.index ["product_id"], name: "index_bundle_deal_items_on_product_id"
  end

  create_table "bundle_deals", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "cta_link", default: "/products"
    t.string "cta_text", default: "Add to Cart"
    t.text "description"
    t.integer "discount_percentage", default: 0
    t.decimal "discounted_price", precision: 10, scale: 2, null: false
    t.string "icon_emoji", default: "💍"
    t.decimal "original_price", precision: 10, scale: 2, null: false
    t.integer "position", default: 0
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_bundle_deals_on_active"
    t.index ["position"], name: "index_bundle_deals_on_position"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "product_variant_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_variant_id"], name: "index_cart_items_on_cart_id_and_product_variant_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["deleted_at"], name: "index_cart_items_on_deleted_at"
    t.index ["product_variant_id"], name: "index_cart_items_on_product_variant_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.datetime "deleted_at"
    t.string "status", default: "active", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_carts_on_customer_id"
    t.index ["deleted_at"], name: "index_carts_on_deleted_at"
    t.index ["status"], name: "index_carts_on_status"
    t.index ["token"], name: "index_carts_on_token", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.jsonb "attribute_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_categories_on_deleted_at"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "coupons", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "discount_type", default: "percentage", null: false
    t.decimal "discount_value", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "expires_at"
    t.decimal "maximum_discount", precision: 10, scale: 2
    t.decimal "minimum_order_amount", precision: 10, scale: 2, default: "0.0"
    t.string "name", null: false
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0, null: false
    t.integer "usage_limit"
    t.index ["active"], name: "index_coupons_on_active"
    t.index ["code"], name: "index_coupons_on_code", unique: true
    t.index ["deleted_at"], name: "index_coupons_on_deleted_at"
  end

  create_table "customers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", null: false
    t.string "first_name", null: false
    t.datetime "last_login_at"
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "homepage_collection_items", force: :cascade do |t|
    t.string "badge_text"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "homepage_collection_id", null: false
    t.string "link_url"
    t.string "overlay_position", default: "bottom_left"
    t.integer "position", default: 0
    t.string "subtitle"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_homepage_collection_items_on_deleted_at"
    t.index ["homepage_collection_id"], name: "index_homepage_collection_items_on_homepage_collection_id"
    t.index ["position"], name: "index_homepage_collection_items_on_position"
  end

  create_table "homepage_collections", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "ends_at"
    t.string "layout_type", default: "grid_4", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "starts_at"
    t.string "subtitle"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_homepage_collections_on_active"
    t.index ["deleted_at"], name: "index_homepage_collections_on_deleted_at"
    t.index ["position"], name: "index_homepage_collections_on_position"
  end

  create_table "homepage_settings", force: :cascade do |t|
    t.boolean "artisan_section_enabled", default: true, null: false
    t.text "bundle_deals_description", default: "Buy matching sets and save big! Perfect combinations for weddings and festivals."
    t.boolean "bundle_deals_enabled", default: true, null: false
    t.string "bundle_deals_heading", default: "Complete Your Look"
    t.string "bundle_deals_title", default: "Bundle and Save"
    t.datetime "created_at", null: false
    t.boolean "ethnic_section_enabled", default: true, null: false
    t.string "flash_sale_cta_link", default: "/products"
    t.string "flash_sale_cta_text", default: "Shop Now"
    t.text "flash_sale_description", default: "Limited time offer on bestselling artificial jewellery. Shop now before it is gone!"
    t.integer "flash_sale_discount", default: 50
    t.boolean "flash_sale_enabled", default: true, null: false
    t.datetime "flash_sale_ends_at"
    t.string "flash_sale_heading", default: "Up to 50% OFF"
    t.string "flash_sale_title", default: "Flash Sale"
    t.boolean "gifts_section_enabled", default: true, null: false
    t.string "hero_subtitle", default: "Exquisite artificial jewellery, thoughtful gifts, and beautiful ethnic wear for every occasion"
    t.string "hero_tagline", default: "Timeless Elegance"
    t.string "promo_banner_code", default: "WELCOME10"
    t.string "promo_banner_cta_link", default: "/products"
    t.string "promo_banner_cta_text", default: "Shop Now"
    t.boolean "promo_banner_enabled", default: true, null: false
    t.string "promo_banner_heading", default: "Get 10% Off"
    t.string "promo_banner_title", default: "First Order Offer"
    t.string "search_placeholder_prefix", default: "Search"
    t.datetime "updated_at", null: false
  end

  create_table "hsn_codes", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "category_name"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.decimal "gst_rate", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_hsn_codes_on_code", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "order_id", null: false
    t.string "product_name", null: false
    t.bigint "product_variant_id"
    t.integer "quantity", default: 1, null: false
    t.string "sku"
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.string "variant_name", null: false
    t.bigint "vendor_id"
    t.index ["deleted_at"], name: "index_order_items_on_deleted_at"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_variant_id"], name: "index_order_items_on_product_variant_id"
    t.index ["vendor_id"], name: "index_order_items_on_vendor_id"
  end

  create_table "orders", force: :cascade do |t|
    t.text "admin_notes"
    t.bigint "billing_address_id"
    t.jsonb "billing_address_snapshot"
    t.string "cancellation_reason"
    t.datetime "cancelled_at"
    t.string "checkout_batch_id"
    t.bigint "coupon_id"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.datetime "deleted_at"
    t.datetime "delivered_at"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "is_draft", default: false, null: false
    t.text "notes"
    t.string "order_number", null: false
    t.string "payment_method", default: "cod", null: false
    t.string "payment_status", default: "pending", null: false
    t.datetime "placed_at"
    t.datetime "shipped_at"
    t.string "shipper_name"
    t.bigint "shipping_address_id"
    t.jsonb "shipping_address_snapshot"
    t.decimal "shipping_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "shipping_carrier"
    t.string "status", default: "pending", null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "tracking_number"
    t.string "tracking_url"
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["billing_address_id"], name: "index_orders_on_billing_address_id"
    t.index ["checkout_batch_id"], name: "index_orders_on_checkout_batch_id"
    t.index ["coupon_id"], name: "index_orders_on_coupon_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["deleted_at"], name: "index_orders_on_deleted_at"
    t.index ["is_draft"], name: "index_orders_on_is_draft"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["shipping_address_id"], name: "index_orders_on_shipping_address_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["vendor_id"], name: "index_orders_on_vendor_id"
  end

  create_table "product_variants", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "color"
    t.decimal "compare_at_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name", null: false
    t.integer "position", default: 0
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "product_id", null: false
    t.jsonb "properties", default: {}
    t.integer "reorder_point", default: 10
    t.integer "reorder_quantity", default: 50
    t.string "size"
    t.string "sku", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.boolean "track_inventory", default: true
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 8, scale: 2
    t.index ["active"], name: "index_product_variants_on_active"
    t.index ["color"], name: "index_product_variants_on_color"
    t.index ["deleted_at"], name: "index_product_variants_on_deleted_at"
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["size"], name: "index_product_variants_on_size"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.string "base_material"
    t.bigint "category_id"
    t.string "country_of_origin", default: "India"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.boolean "featured", default: false, null: false
    t.string "gemstone"
    t.boolean "hot_selling", default: false, null: false
    t.bigint "hsn_code_id"
    t.string "ideal_for"
    t.string "name", null: false
    t.string "occasion"
    t.string "plating"
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.jsonb "properties", default: {}
    t.integer "ratings_count", default: 0
    t.text "short_description"
    t.string "sku"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["active"], name: "index_products_on_active"
    t.index ["base_material"], name: "index_products_on_base_material"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["gemstone"], name: "index_products_on_gemstone"
    t.index ["hot_selling"], name: "index_products_on_hot_selling"
    t.index ["hsn_code_id"], name: "index_products_on_hsn_code_id"
    t.index ["ideal_for"], name: "index_products_on_ideal_for"
    t.index ["occasion"], name: "index_products_on_occasion"
    t.index ["plating"], name: "index_products_on_plating"
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["vendor_id"], name: "index_products_on_vendor_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "admin_response"
    t.boolean "approved", default: false, null: false
    t.datetime "approved_at"
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.datetime "deleted_at"
    t.bigint "order_id"
    t.bigint "product_id", null: false
    t.integer "rating", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_reviews_on_customer_id"
    t.index ["deleted_at"], name: "index_reviews_on_deleted_at"
    t.index ["order_id"], name: "index_reviews_on_order_id"
    t.index ["product_id", "approved"], name: "index_reviews_on_product_id_and_approved"
    t.index ["product_id"], name: "index_reviews_on_product_id"
  end

  create_table "stock_adjustments", force: :cascade do |t|
    t.bigint "adjusted_by_id"
    t.string "adjusted_by_type"
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "product_variant_id", null: false
    t.integer "quantity_after", null: false
    t.integer "quantity_before", null: false
    t.integer "quantity_change", null: false
    t.string "reason", null: false
    t.datetime "updated_at", null: false
    t.index ["adjusted_by_type", "adjusted_by_id"], name: "index_stock_adjustments_on_adjusted_by"
    t.index ["created_at"], name: "index_stock_adjustments_on_created_at"
    t.index ["product_variant_id"], name: "index_stock_adjustments_on_product_variant_id"
    t.index ["reason"], name: "index_stock_adjustments_on_reason"
  end

  create_table "store_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "filter_config", default: {}, null: false
    t.datetime "updated_at", null: false
  end

  create_table "support_tickets", force: :cascade do |t|
    t.datetime "admin_last_seen_at"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.datetime "customer_last_seen_at"
    t.datetime "deleted_at"
    t.datetime "last_message_at"
    t.string "last_message_sender_type"
    t.bigint "order_id"
    t.string "priority", default: "normal", null: false
    t.datetime "resolved_at"
    t.string "status", default: "open", null: false
    t.string "subject", null: false
    t.string "ticket_number", null: false
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["admin_last_seen_at"], name: "index_support_tickets_on_admin_last_seen_at"
    t.index ["customer_id"], name: "index_support_tickets_on_customer_id"
    t.index ["customer_last_seen_at"], name: "index_support_tickets_on_customer_last_seen_at"
    t.index ["deleted_at"], name: "index_support_tickets_on_deleted_at"
    t.index ["last_message_at"], name: "index_support_tickets_on_last_message_at"
    t.index ["last_message_sender_type"], name: "index_support_tickets_on_last_message_sender_type"
    t.index ["order_id"], name: "index_support_tickets_on_order_id"
    t.index ["status"], name: "index_support_tickets_on_status"
    t.index ["ticket_number"], name: "index_support_tickets_on_ticket_number", unique: true
    t.index ["vendor_id"], name: "index_support_tickets_on_vendor_id"
  end

  create_table "ticket_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "sender_id", null: false
    t.string "sender_type", null: false
    t.bigint "support_ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_ticket_messages_on_deleted_at"
    t.index ["sender_type", "sender_id"], name: "index_ticket_messages_on_sender_type_and_sender_id"
    t.index ["support_ticket_id"], name: "index_ticket_messages_on_support_ticket_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "address_line1"
    t.string "address_line2"
    t.string "business_name", null: false
    t.string "city"
    t.string "contact_name", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", null: false
    t.string "gst_number"
    t.string "phone"
    t.string "pincode"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_vendors_on_deleted_at"
    t.index ["email"], name: "index_vendors_on_email", unique: true
  end

  create_table "wishlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "product_id"], name: "index_wishlists_on_customer_id_and_product_id", unique: true
    t.index ["customer_id"], name: "index_wishlists_on_customer_id"
    t.index ["product_id"], name: "index_wishlists_on_product_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "customers"
  add_foreign_key "admin_users", "vendors"
  add_foreign_key "bundle_deal_items", "bundle_deals"
  add_foreign_key "bundle_deal_items", "products"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "product_variants"
  add_foreign_key "carts", "customers"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "homepage_collection_items", "homepage_collections"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants"
  add_foreign_key "order_items", "vendors"
  add_foreign_key "orders", "coupons"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "vendors"
  add_foreign_key "product_variants", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "hsn_codes"
  add_foreign_key "products", "vendors"
  add_foreign_key "reviews", "customers"
  add_foreign_key "reviews", "orders"
  add_foreign_key "reviews", "products"
  add_foreign_key "stock_adjustments", "product_variants"
  add_foreign_key "support_tickets", "customers"
  add_foreign_key "support_tickets", "orders"
  add_foreign_key "support_tickets", "vendors"
  add_foreign_key "ticket_messages", "support_tickets"
  add_foreign_key "wishlists", "customers"
  add_foreign_key "wishlists", "products"
end
