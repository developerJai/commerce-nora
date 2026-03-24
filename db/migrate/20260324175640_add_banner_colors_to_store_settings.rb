class AddBannerColorsToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :banner_bg_color, :string, default: "#7A0C14"
    add_column :store_settings, :banner_text_color, :string, default: "#FFFFFF"
    add_column :store_settings, :banner_accent_color, :string, default: "#FFD700"
  end
end
