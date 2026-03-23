class SitemapsController < ApplicationController
  def show
    @base_url = request.base_url
    @static_pages = [
      { path: root_path, priority: 1.0, changefreq: 'daily' },
      { path: login_path, priority: 0.6, changefreq: 'monthly' },
      { path: signup_path, priority: 0.6, changefreq: 'monthly' },
      { path: products_path, priority: 0.9, changefreq: 'daily' },
      { path: about_path, priority: 0.5, changefreq: 'monthly' },
      { path: shipping_path, priority: 0.4, changefreq: 'monthly' },
      { path: returns_path, priority: 0.4, changefreq: 'monthly' },
      { path: privacy_path, priority: 0.3, changefreq: 'yearly' },
      { path: terms_path, priority: 0.3, changefreq: 'yearly' }
    ]

    @categories = Category.active.includes(:parent)
    @products = Product.active.includes(:variants, :category, images_attachments: :blob)

    respond_to do |format|
      format.xml
    end
  end
end
