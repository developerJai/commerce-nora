class AddGstNumberToStoreSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :store_settings, :gst_number, :string
    add_column :store_settings, :company_address, :text
    add_column :store_settings, :company_phone, :string
    add_column :store_settings, :enable_coupons, :boolean, default: true
  end
end
