class AddSlugToVendors < ActiveRecord::Migration[8.1]
  def up
    add_column :vendors, :slug, :string

    # Backfill slugs for existing vendors
    Vendor.reset_column_information
    Vendor.find_each do |vendor|
      base_slug = vendor.business_name.parameterize
      slug = base_slug
      counter = 2
      while Vendor.where(slug: slug).where.not(id: vendor.id).exists?
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end
      vendor.update_column(:slug, slug)
    end

    change_column_null :vendors, :slug, false
    add_index :vendors, :slug, unique: true
  end

  def down
    remove_index :vendors, :slug
    remove_column :vendors, :slug
  end
end
