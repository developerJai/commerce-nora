class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.text :short_description
      t.references :category, foreign_key: true
      t.string :sku
      t.decimal :price, precision: 10, scale: 2, default: 0
      t.boolean :active, default: true, null: false
      t.boolean :featured, default: false, null: false
      t.decimal :average_rating, precision: 3, scale: 2, default: 0
      t.integer :ratings_count, default: 0

      t.timestamps
    end
    add_index :products, :slug, unique: true
    add_index :products, :active
    add_index :products, :featured
  end
end
