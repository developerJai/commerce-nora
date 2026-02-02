class ProductsController < ApplicationController
  def index
    @q = params[:q]
    @category_id = params[:category_id]
    @min_price = params[:min_price]
    @max_price = params[:max_price]
    @sort = params[:sort] || 'newest'

    products = Product.active.includes(:category, :variants, images_attachments: :blob)
    products = products.search(@q) if @q.present?
    products = products.with_category(@category_id) if @category_id.present?
    
    if @min_price.present? || @max_price.present?
      products = products.joins(:variants).where(product_variants: { active: true })
      products = products.where("product_variants.price >= ?", @min_price) if @min_price.present?
      products = products.where("product_variants.price <= ?", @max_price) if @max_price.present?
      products = products.distinct
    end

    products = case @sort
    when 'price_low'
      products.left_joins(:variants).group(:id).order('MIN(product_variants.price) ASC')
    when 'price_high'
      products.left_joins(:variants).group(:id).order('MIN(product_variants.price) DESC')
    when 'name'
      products.order(:name)
    when 'rating'
      products.order(average_rating: :desc)
    else
      products.order(created_at: :desc)
    end

    @pagy, @products = pagy(products, items: 12)
    @categories = Category.active.ordered
  end

  def show
    @product = Product.active.includes(:variants, :category, images_attachments: :blob).find_by!(slug: params[:slug])
    @variants = @product.variants.active.ordered
    @reviews = @product.approved_reviews.includes(:customer).recent.limit(10)
    @related_products = Product.active.where(category_id: @product.category_id)
                               .where.not(id: @product.id)
                               .includes(:variants, images_attachments: :blob)
                               .limit(4)
  end
end
