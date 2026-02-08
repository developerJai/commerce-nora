class CreateHomepageCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :homepage_collections do |t|
      t.string :name, null: false
      t.string :subtitle
      t.string :layout_type, null: false, default: "grid_4"
      t.integer :position, default: 0
      t.boolean :active, default: true, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :homepage_collections, :active
    add_index :homepage_collections, :position
    add_index :homepage_collections, :deleted_at

    create_table :homepage_collection_items do |t|
      t.references :homepage_collection, null: false, foreign_key: true
      t.string :title
      t.string :subtitle
      t.string :badge_text
      t.string :link_url
      t.integer :position, default: 0
      t.string :overlay_position, default: "bottom_left"
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :homepage_collection_items, :position
    add_index :homepage_collection_items, :deleted_at
  end
end
