class HomeController < ApplicationController
  def index
    @homepage_settings = HomepageSetting.current
    @banners = Banner.visible.limit(5)
    @homepage_collections = HomepageCollection.visible.includes(items: { image_attachment: :blob })
    @featured_products = Product.active.featured.includes({ variants: { image_attachment: :blob } }, images_attachments: :blob).limit(10)
    # Ensure minimum 6 bestseller listings
    if @featured_products.length < 6
      existing_ids = @featured_products.map(&:id)
      filler = Product.active.where.not(id: existing_ids).includes({ variants: { image_attachment: :blob } }, images_attachments: :blob).order(created_at: :desc).limit(6 - @featured_products.length)
      @featured_products = @featured_products + filler
    end
    @hot_selling_products = Product.active.hot_selling.includes({ variants: { image_attachment: :blob } }, images_attachments: :blob).limit(8)
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

    @hero_heading_highlight = if hero_parts.length > 1
                                "#{hero_parts[0..-2].join(', ')} & #{hero_parts.last}"
    else
                                "Exquisite Jewellery"
    end

    @hero_heading = "Discover #{@hero_heading_highlight}"

    # Dynamic search placeholder
    @search_placeholder = "Search #{hero_parts.join(', ')}..."
  end
end
