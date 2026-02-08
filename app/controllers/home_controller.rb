class HomeController < ApplicationController
  def index
    @banners = Banner.visible.limit(5)
    @homepage_collections = HomepageCollection.visible.includes(items: { image_attachment: :blob })
    @featured_products = Product.active.featured.includes({ variants: { image_attachment: :blob } }, images_attachments: :blob).limit(10)
    @new_arrivals = Product.active.includes({ variants: { image_attachment: :blob } }, images_attachments: :blob).order(created_at: :desc).limit(10)
    @categories = Category.active.root.ordered.limit(6)
  end
end
