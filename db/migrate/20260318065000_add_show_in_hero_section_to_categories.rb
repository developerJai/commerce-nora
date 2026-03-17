class AddShowInHeroSectionToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :show_in_hero_section, :boolean, default: false, null: false
    add_index :categories, :show_in_hero_section
  end
end
