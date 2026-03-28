class AddEnableMultiVendorCouponsToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :enable_multi_vendor_coupons, :boolean, default: false, null: false
  end
end
