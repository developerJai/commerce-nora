class CreateAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :admins do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.boolean :active, default: true, null: false
      t.datetime :last_login_at

      t.timestamps
    end
    add_index :admins, :email, unique: true
  end
end
