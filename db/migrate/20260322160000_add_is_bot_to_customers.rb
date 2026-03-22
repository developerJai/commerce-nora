class AddIsBotToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :is_bot, :boolean, default: false, null: false

    # Mark existing seed review customers as bots
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE customers SET is_bot = true WHERE email LIKE '%@example.com'
        SQL
      end
    end
  end
end
