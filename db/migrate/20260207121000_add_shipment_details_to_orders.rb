class AddShipmentDetailsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :shipping_carrier, :string
    add_column :orders, :tracking_number, :string
    add_column :orders, :tracking_url, :string
    add_column :orders, :shipper_name, :string
  end
end
