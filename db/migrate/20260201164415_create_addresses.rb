class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :address_type, default: 'shipping', null: false # shipping, billing
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.string :street_address, null: false
      t.string :apartment
      t.string :city, null: false
      t.string :state, null: false
      t.string :postal_code, null: false
      t.string :country, null: false, default: 'US'
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end
    add_index :addresses, [:customer_id, :address_type]
  end
end
