class AddCancellationReasonToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :cancellation_reason, :string
  end
end
