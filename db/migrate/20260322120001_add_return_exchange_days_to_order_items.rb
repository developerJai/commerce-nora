class AddReturnExchangeDaysToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :return_in_days, :integer, default: 0, null: false
    add_column :order_items, :exchange_in_days, :integer, default: 0, null: false
  end
end
