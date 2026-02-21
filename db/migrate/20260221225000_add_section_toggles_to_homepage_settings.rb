class AddSectionTogglesToHomepageSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :homepage_settings, :gifts_section_enabled, :boolean, default: true, null: false
    add_column :homepage_settings, :artisan_section_enabled, :boolean, default: true, null: false
    add_column :homepage_settings, :ethnic_section_enabled, :boolean, default: true, null: false
  end
end
