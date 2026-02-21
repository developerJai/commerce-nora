class CreateBundleDealItems < ActiveRecord::Migration[8.1]
  def change
    create_table :bundle_deal_items do |t|
      t.references :bundle_deal, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, default: 1, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :bundle_deal_items, [ :bundle_deal_id, :product_id ], unique: true
  end
end
