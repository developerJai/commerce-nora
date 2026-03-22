class AddReturnExchangeDaysToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :return_in_days, :integer, default: 0, null: false
    add_column :products, :exchange_in_days, :integer, default: 0, null: false
  end
end
