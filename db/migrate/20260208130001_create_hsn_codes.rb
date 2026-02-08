class CreateHsnCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :hsn_codes do |t|
      t.string :code, null: false
      t.string :description, null: false
      t.decimal :gst_rate, precision: 5, scale: 2, null: false
      t.string :category_name
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :hsn_codes, :code, unique: true
  end
end
