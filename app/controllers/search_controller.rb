class SearchController < ApplicationController
  def index
    @q = params[:q]

    if @q.present?
      # Always redirect to products with search query to keep consistent behavior
      redirect_to products_path(q: @q)
    else
      redirect_to products_path
    end
  end

  def suggestions
    query = params[:q].to_s.strip

    if query.length < 2
      render json: { categories: [], products: [], variants: [] }
      return
    end

    # Search categories - only show root categories (parent_id: nil) that are active
    # This ensures we don't show subcategories with disabled parents
    categories = Category.active.root
                        .where("name ILIKE ?", "%#{query}%")
                        .limit(3)
                        .map do |cat|

      {
        id: cat.id,
        name: cat.name,
        slug: cat.slug,
        products_count: cat.products.active.count
      }
    end

    # Search products
    products = Product.active
                     .where("products.name ILIKE ? OR products.description ILIKE ?", "%#{query}%", "%#{query}%")
                     .includes(:variants, images_attachments: :blob)
                     .limit(5)
                     .map do |product|
      variant = product.default_variant
      {
        id: product.id,
        name: product.name,
        slug: product.slug,
        price: helpers.format_price(product.min_price),
        in_stock: product.in_stock?,
        image: product.images.attached? ? url_for(product.images.first.variant(resize_to_fill: [ 80, 80 ])) : nil
      }
    end

    # Search variants by SKU or name
    variants = ProductVariant.active
                            .joins(:product)
                            .where(products: { active: true, deleted_at: nil })
                            .where("product_variants.name ILIKE ? OR product_variants.sku ILIKE ?", "%#{query}%", "%#{query}%")
                            .includes(:product, image_attachment: :blob)
                            .limit(5)
                            .map do |variant|
      {
        id: variant.id,
        name: variant.name,
        slug: variant.slug,
        variant_param: variant.name.parameterize,
        sku: variant.sku,
        product_name: variant.product.name,
        product_slug: variant.product.slug,
        price: helpers.format_price(variant.price),
        stock_quantity: variant.stock_quantity,
        image: variant.image.attached? ? url_for(variant.image.variant(resize_to_fill: [ 80, 80 ])) : nil
      }
    end

    render json: {
      categories: categories,
      products: products,
      variants: variants
    }
  end
end
