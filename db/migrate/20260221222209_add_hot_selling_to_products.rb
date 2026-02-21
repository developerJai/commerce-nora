class AddHotSellingToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :hot_selling, :boolean, default: false, null: false
    add_index :products, :hot_selling
  end
end
