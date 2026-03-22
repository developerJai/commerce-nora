class AddDeliverySettingsToStoreSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :store_settings, :free_delivery_min_amount, :decimal, precision: 10, scale: 2, default: 499.0, null: false
    add_column :store_settings, :delivery_charge_amount, :decimal, precision: 10, scale: 2, default: 99.0, null: false
  end
end
