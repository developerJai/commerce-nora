class CreateStoreSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :store_settings do |t|
      t.jsonb :filter_config, null: false, default: {}
      t.timestamps
    end
  end
end
