class CategoriesController < ApplicationController
  include Pagy::Backend

  def show
    @category = Category.active.find_by!(slug: params[:slug])
    products = @category.products.active.includes(:variants, images_attachments: :blob)
    
    # Apply price filters
    if params[:min_price].present?
      products = products.joins(:variants).where('product_variants.price >= ?', params[:min_price].to_f).distinct
    end
    if params[:max_price].present?
      products = products.joins(:variants).where('product_variants.price <= ?', params[:max_price].to_f).distinct
    end
    
    @sort = params[:sort] || 'newest'
    products = case @sort
    when 'price_asc'
      products.left_joins(:variants).group('products.id').order('MIN(product_variants.price) ASC')
    when 'price_desc'
      products.left_joins(:variants).group('products.id').order('MIN(product_variants.price) DESC')
    when 'name'
      products.order(:name)
    when 'rating'
      products.order(average_rating: :desc)
    else
      products.order(created_at: :desc)
    end

    @pagy, @products = pagy(products, items: 12)
    @subcategories = @category.children.active.ordered
  end
end
