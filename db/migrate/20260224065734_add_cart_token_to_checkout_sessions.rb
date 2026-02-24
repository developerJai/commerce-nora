class AddCartTokenToCheckoutSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :checkout_sessions, :cart_token, :string
  end
end
