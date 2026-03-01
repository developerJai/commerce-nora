class AddCountryCodeToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :country_code, :string, default: '+91'
  end
end
