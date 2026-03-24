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

    # Search products - use the same .active scope as the products list page
    # which filters by active vendor, active category, and active product
    products = Product.active
                     .search(query)
                     .includes(variants: { image_attachment: :blob }, images_attachments: :blob)
                     .limit(5)
                     .map do |product|
      variant = product.default_variant
      image = if variant&.image&.attached?
                url_for(variant.image)
              elsif product.images.attached?
                url_for(product.images.first)
              end
      {
        id: product.id,
        name: product.name,
        slug: product.slug,
        price: helpers.format_price(product.min_price),
        in_stock: product.in_stock?,
        image: image
      }
    end

    # Search variants - join through product's active scope to respect vendor/category filters
    variants = ProductVariant.active
                            .joins(product: [:vendor, :category])
                            .where(products: { active: true, deleted_at: nil })
                            .where("vendors.active IS NULL OR vendors.active = ?", true)
                            .where("categories.active IS NULL OR categories.active = ?", true)
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
        image: variant.image.attached? ? url_for(variant.image) : nil
      }
    end

    render json: {
      categories: categories,
      products: products,
      variants: variants
    }
  end
end
