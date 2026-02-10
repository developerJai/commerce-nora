class HomeController < ApplicationController
  def index
    @banners = Banner.visible.limit(5)
    @homepage_collections = HomepageCollection.visible.includes(items: { image_attachment: :blob })
    @featured_products = Product.active.featured.includes({ variants: { image_attachment: :blob } }, images_attachments: :blob).limit(10)
    @new_arrivals = Product.active.includes({ variants: { image_attachment: :blob } }, images_attachments: :blob).order(created_at: :desc).limit(10)
    @categories = Category.active.root.ordered.includes(image_attachment: :blob).limit(8)

    # Dynamic hero heading based on active categories
    active_categories = Category.active.root.ordered.pluck(:name)
    hero_parts = []

    hero_parts << "Jewellery"

    # Add "traditional wear" if active
    if active_categories.include?("Traditional Wear")
      hero_parts << "Traditional Wear"
    end

    # Add "gifts" if active
    if active_categories.include?("Gifts")
      hero_parts << "Gifts"
    end

    @hero_heading = if hero_parts.length > 1
                       "Discover #{hero_parts[0..-2].join(', ')} & #{hero_parts.last}"
                     else
                       "Discover Exquisite Jewellery"
                     end

    # Dynamic search placeholder
    @search_placeholder = "Search #{hero_parts.join(', ')}..."
  end
end
