class CreateAppVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :app_versions do |t|
      t.string :platform, null: false
      t.string :version_number, null: false
      t.boolean :force_update, default: false, null: false
      t.boolean :active, default: true, null: false
      t.text :release_notes
      t.string :store_url
      t.datetime :released_at

      t.timestamps
    end

    add_index :app_versions, [ :platform, :version_number ], unique: true
    add_index :app_versions, [ :platform, :active ]
  end
end
