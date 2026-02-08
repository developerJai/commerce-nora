class CreateVendors < ActiveRecord::Migration[8.1]
  def change
    create_table :vendors do |t|
      t.string :business_name, null: false
      t.string :contact_name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :gst_number
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :pincode
      t.boolean :active, default: true
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :vendors, :email, unique: true
    add_index :vendors, :deleted_at
  end
end
