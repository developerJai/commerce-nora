class HomeController < ApplicationController
  def index
    @banners = Banner.visible.limit(5)
    @featured_products = Product.active.featured.includes(:variants, images_attachments: :blob).limit(8)
    @new_arrivals = Product.active.includes(:variants, images_attachments: :blob).order(created_at: :desc).limit(8)
    @categories = Category.active.root.ordered.limit(6)
  end
end
