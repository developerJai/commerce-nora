class AddMobileAppSettingsToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :mobile_apps_enabled, :boolean, default: false, null: false
    add_column :store_settings, :ios_app_url, :string
    add_column :store_settings, :android_app_url, :string
    add_column :store_settings, :mobile_app_section_title, :string, default: "Shop on the Go"
    add_column :store_settings, :mobile_app_section_subtitle, :string, default: "Download our app for exclusive deals, faster checkout, and a personalised shopping experience"
  end
end
