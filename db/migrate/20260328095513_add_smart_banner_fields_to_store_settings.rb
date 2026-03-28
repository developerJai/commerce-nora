class AddSmartBannerFieldsToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :smart_banner_title, :string
    add_column :store_settings, :smart_banner_subtitle, :string
  end
end
