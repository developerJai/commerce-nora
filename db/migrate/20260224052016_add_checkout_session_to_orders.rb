class AddCheckoutSessionToOrders < ActiveRecord::Migration[8.1]
  def change
    # Add checkout session reference (nullable for existing orders)
    add_reference :orders, :checkout_session, null: true, foreign_key: true

    # Remove unique index from razorpay_order_id to allow multiple orders per payment
    remove_index :orders, :razorpay_order_id, if_exists: true

    # Add non-unique index for performance
    add_index :orders, :razorpay_order_id, if_not_exists: true
  end
end
