class AddTokenToAddresses < ActiveRecord::Migration[8.0]
  def up
    add_column :addresses, :token, :string

    # Backfill existing addresses with unique tokens
    execute <<-SQL.squish
      UPDATE addresses
      SET token = substr(md5(random()::text), 1, 11)
      WHERE token IS NULL
    SQL

    change_column_null :addresses, :token, false
    add_index :addresses, :token, unique: true
  end

  def down
    remove_index :addresses, :token
    remove_column :addresses, :token
  end
end
