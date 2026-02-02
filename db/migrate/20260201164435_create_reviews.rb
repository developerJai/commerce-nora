class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :customer, foreign_key: true
      t.references :order, foreign_key: true
      t.integer :rating, null: false
      t.string :title
      t.text :body
      t.boolean :approved, default: false, null: false
      t.datetime :approved_at
      t.text :admin_response

      t.timestamps
    end
    add_index :reviews, [:product_id, :approved]
  end
end
