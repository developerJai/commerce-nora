class CreateCarts < ActiveRecord::Migration[8.0]
  def change
    create_table :carts do |t|
      t.references :customer, foreign_key: true
      t.string :token, null: false
      t.string :status, default: 'active', null: false

      t.timestamps
    end
    add_index :carts, :token, unique: true
    add_index :carts, :status
  end
end
