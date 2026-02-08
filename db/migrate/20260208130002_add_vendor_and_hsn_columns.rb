class AddVendorAndHsnColumns < ActiveRecord::Migration[8.1]
  def change
    # AdminUser: role-based access
    add_column :admin_users, :role, :string, default: 'admin', null: false
    add_reference :admin_users, :vendor, null: true, foreign_key: true

    # Products: vendor ownership + HSN tax classification
    add_reference :products, :vendor, null: true, foreign_key: true
    add_reference :products, :hsn_code, null: true, foreign_key: true

    # Orders: vendor ownership + checkout batch grouping
    add_reference :orders, :vendor, null: true, foreign_key: true
    add_column :orders, :checkout_batch_id, :string

    # OrderItems: denormalized vendor_id for query performance
    add_reference :order_items, :vendor, null: true, foreign_key: true

    # SupportTickets: vendor-to-admin tickets
    add_reference :support_tickets, :vendor, null: true, foreign_key: true

    add_index :admin_users, :role
    add_index :orders, :checkout_batch_id
  end
end
