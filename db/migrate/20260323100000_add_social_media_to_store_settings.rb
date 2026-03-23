class AddSocialMediaToStoreSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :store_settings, :youtube_url, :string
    add_column :store_settings, :instagram_url, :string
    add_column :store_settings, :facebook_url, :string
    add_column :store_settings, :twitter_url, :string
  end
end
