class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.boolean :active, default: true, null: false
      t.datetime :last_login_at

      t.timestamps
    end
    add_index :customers, :email, unique: true
  end
end
