class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :parent, foreign_key: { to_table: :categories }
      t.integer :position, default: 0
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :categories, :slug, unique: true
  end
end
