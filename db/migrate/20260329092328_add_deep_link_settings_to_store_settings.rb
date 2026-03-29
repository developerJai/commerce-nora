class AddDeepLinkSettingsToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :ios_team_id, :string
    add_column :store_settings, :ios_bundle_id, :string
    add_column :store_settings, :android_package_name, :string
    add_column :store_settings, :android_sha256_fingerprint, :string
  end
end
