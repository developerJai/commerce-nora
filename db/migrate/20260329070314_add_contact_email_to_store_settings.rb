class AddContactEmailToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :contact_email, :string
  end
end
