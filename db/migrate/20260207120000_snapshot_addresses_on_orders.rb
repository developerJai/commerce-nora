class SnapshotAddressesOnOrders < ActiveRecord::Migration[8.0]
  def up
    # Add JSONB columns to store address snapshots directly on the order
    add_column :orders, :shipping_address_snapshot, :jsonb
    add_column :orders, :billing_address_snapshot, :jsonb

    # Backfill existing orders from their referenced address records
    execute <<-SQL.squish
      UPDATE orders
      SET shipping_address_snapshot = (
        SELECT jsonb_build_object(
          'first_name', a.first_name,
          'last_name',  a.last_name,
          'phone',      a.phone,
          'street_address', a.street_address,
          'apartment',  a.apartment,
          'city',       a.city,
          'state',      a.state,
          'postal_code', a.postal_code,
          'country',    a.country
        )
        FROM addresses a WHERE a.id = orders.shipping_address_id
      )
      WHERE shipping_address_id IS NOT NULL
    SQL

    execute <<-SQL.squish
      UPDATE orders
      SET billing_address_snapshot = (
        SELECT jsonb_build_object(
          'first_name', a.first_name,
          'last_name',  a.last_name,
          'phone',      a.phone,
          'street_address', a.street_address,
          'apartment',  a.apartment,
          'city',       a.city,
          'state',      a.state,
          'postal_code', a.postal_code,
          'country',    a.country
        )
        FROM addresses a WHERE a.id = orders.billing_address_id
      )
      WHERE billing_address_id IS NOT NULL
    SQL

    # Remove hard foreign key constraints so addresses can be deleted freely.
    # The ID columns are kept as historical references.
    remove_foreign_key :orders, :addresses, column: :shipping_address_id
    remove_foreign_key :orders, :addresses, column: :billing_address_id
  end

  def down
    add_foreign_key :orders, :addresses, column: :shipping_address_id
    add_foreign_key :orders, :addresses, column: :billing_address_id

    remove_column :orders, :shipping_address_snapshot
    remove_column :orders, :billing_address_snapshot
  end
end
