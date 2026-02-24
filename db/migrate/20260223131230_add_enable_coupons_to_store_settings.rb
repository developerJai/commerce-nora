class AddEnableCouponsToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :enable_coupons, :boolean, default: true
  end
end
