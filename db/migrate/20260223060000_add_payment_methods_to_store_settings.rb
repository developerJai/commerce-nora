class AddPaymentMethodsToStoreSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :store_settings, :payment_config, :jsonb, default: {}
  end
end
