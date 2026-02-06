class ProductsController < ApplicationController
  def index
    @category_ids = Array(params[:category_ids]).reject(&:blank?)
    @min_price = params[:min_price]
    @max_price = params[:max_price]
    @sort = params[:sort].presence || 'rating'

    variants_scope = ProductVariant.where(active: true)
    @catalog_min_price = variants_scope.minimum(:price).to_f.floor
    @catalog_max_price = variants_scope.maximum(:price).to_f.ceil

    products = Product.active.includes(:category, :variants, images_attachments: :blob)

    if @category_ids.any?
      products = products.where(category_id: @category_ids)
    end

    if @min_price.present? || @max_price.present?
      # Filter by each product's minimum active variant price (the "starting at" price
      # shown on the card), so displayed prices always fall within the slider range.
      price_filter = ProductVariant.where(active: true).group(:product_id)
      price_filter = price_filter.having("MIN(price) >= ?", @min_price.to_f) if @min_price.present?
      price_filter = price_filter.having("MIN(price) <= ?", @max_price.to_f) if @max_price.present?
      products = products.where(id: price_filter.select(:product_id))
    end

    products = case @sort
    when 'price_low'
      products.left_joins(:variants).where(product_variants: { active: true }).group(:id).order('MIN(product_variants.price) ASC')
    when 'price_high'
      products.left_joins(:variants).where(product_variants: { active: true }).group(:id).order('MIN(product_variants.price) DESC')
    when 'rating'
      products.order(average_rating: :desc)
    else
      products.order(created_at: :desc)
    end

    @pagy, @products = pagy(products, limit: 16)
    @categories = Category.active.ordered

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @product = Product.active.includes(:variants, :category, images_attachments: :blob).find_by!(slug: params[:slug])
    @variants = @product.variants.active.ordered
    @reviews = @product.approved_reviews.includes(:customer).recent.limit(10)
    @related_products = Product.active.where(category_id: @product.category_id)
                               .where.not(id: @product.id)
                               .includes(:variants, images_attachments: :blob)
                               .limit(4)
    
    # Get the selected variant (from URL param or default to first)
    @selected_variant = if params[:variant].present?
      @variants.find { |v| v.name.parameterize == params[:variant] } || @variants.first
    else
      @variants.first
    end
    
    # Get cart item for the selected variant if it exists
    @cart_item = @selected_variant ? current_cart.cart_items.find_by(product_variant: @selected_variant) : nil
  end
end
