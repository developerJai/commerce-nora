class AddDeletedAtToAllModels < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_users, :deleted_at, :datetime
    add_column :customers, :deleted_at, :datetime
    add_column :categories, :deleted_at, :datetime
    add_column :products, :deleted_at, :datetime
    add_column :product_variants, :deleted_at, :datetime
    add_column :addresses, :deleted_at, :datetime
    add_column :carts, :deleted_at, :datetime
    add_column :cart_items, :deleted_at, :datetime
    add_column :coupons, :deleted_at, :datetime
    add_column :orders, :deleted_at, :datetime
    add_column :order_items, :deleted_at, :datetime
    add_column :reviews, :deleted_at, :datetime
    add_column :support_tickets, :deleted_at, :datetime
    add_column :ticket_messages, :deleted_at, :datetime
    add_column :banners, :deleted_at, :datetime

    add_index :admin_users, :deleted_at
    add_index :customers, :deleted_at
    add_index :categories, :deleted_at
    add_index :products, :deleted_at
    add_index :product_variants, :deleted_at
    add_index :addresses, :deleted_at
    add_index :carts, :deleted_at
    add_index :cart_items, :deleted_at
    add_index :coupons, :deleted_at
    add_index :orders, :deleted_at
    add_index :order_items, :deleted_at
    add_index :reviews, :deleted_at
    add_index :support_tickets, :deleted_at
    add_index :ticket_messages, :deleted_at
    add_index :banners, :deleted_at
  end
end
