class AddMissingFieldsToCheckoutSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :checkout_sessions, :paid_at, :datetime
    add_column :checkout_sessions, :failed_at, :datetime
    add_column :checkout_sessions, :error_message, :text
    add_column :checkout_sessions, :razorpay_payment_id, :string
  end
end
