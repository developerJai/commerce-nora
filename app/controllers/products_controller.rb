class ProductsController < ApplicationController
  include ProductFiltering

  def index
    # ── Parse filter params ──────────────────────────────────────────
    parse_filter_params

    # ── Catalog price bounds ─────────────────────────────────────────
    variants_scope = ProductVariant.where(active: true)
    @catalog_min_price = variants_scope.minimum(:price).to_f.floor
    @catalog_max_price = variants_scope.maximum(:price).to_f.ceil

    # ── Build base product IDs with all non-multiselect filters ───────
    # This is used for facet calculation (standard e-commerce approach)
    base_product_ids = build_filtered_product_ids(
      category_ids: @category_ids,
      rating: @rating,
      in_stock: @in_stock,
      min_price: @min_price,
      max_price: @max_price,
      discount: @discount,
      q: @q
    )

    # ── Build facets from base filtered products (BEFORE multiselect) ──
    # This ensures all available options are shown, not just filtered subset
    @facets = build_facets_from_ids(base_product_ids, @in_stock)

    # ── Calculate category counts WITHOUT category filter ──────────────
    # This ensures all categories remain visible when selecting any filters
    category_count_product_ids = build_filtered_product_ids(
      category_ids: [],  # Exclude category filter for category counts
      rating: @rating,
      in_stock: @in_stock,
      min_price: @min_price,
      max_price: @max_price,
      discount: @discount,
      q: @q
    )
    @category_counts = Product.where(id: category_count_product_ids).group(:category_id).count

    # ── Apply multiselect filters to get final product IDs ───────────
    final_product_ids = apply_multiselect_filters(
      base_product_ids,
      colors: @colors,
      materials: @materials,
      gemstones: @gemstones,
      occasions: @occasions,
      in_stock: @in_stock
    )

    # ── Sort and paginate ───────────────────────────────────────────
    products = build_sorted_products(final_product_ids, @sort, @in_stock)

    per_page = helpers.mobile_request? ? 16 : 15
    @pagy, @products = pagy(products, limit: per_page, count: final_product_ids.length)
    @category_tree = Category.grouped_for_filters

    # ── Filter visibility (admin-configurable) ───────────────────────
    @filter_config = StoreSetting.instance.effective_filter_config

    # ── Active filters (for chips display) ───────────────────────────
    @active_filters = build_active_filters_with_config

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @product = Product.active.includes(
      :category,
      { variants: { image_attachment: :blob } },
      images_attachments: :blob
    ).find_by(slug: params[:slug])

    unless @product
      redirect_to products_path, alert: "This product is currently unavailable."
      return
    end

    @variants = @product.variants.active.ordered
    @reviews = @product.approved_reviews.includes(:customer).recent.limit(10)
    @related_products = if @product.category_id.present?
                          Product.active.where(category_id: @product.category_id)
                                 .where.not(id: @product.id)
                                 .includes({ variants: { image_attachment: :blob } }, images_attachments: :blob)
                                 .limit(4)
    else
                          Product.none
    end

    @selected_variant = if params[:variant].present?
      # Search by parameterizing the name since slug is not a database column
      found_variant = @variants.find { |v| v.name.parameterize == params[:variant] }
      found_variant || @variants.first
    else
      @variants.first
    end

    @cart_item = @selected_variant ? current_cart.cart_items.find_by(product_variant: @selected_variant) : nil

    # Available offers for display
    @available_coupons = Coupon.available.limit(3)

    # Rating distribution for review section
    if @product.ratings_count > 0
      @rating_distribution = @product.approved_reviews.group(:rating).count
    else
      @rating_distribution = {}
    end
  end

  private

  # Products page has additional filter config awareness for subcategory visibility
  def build_active_filters_with_config
    filters = build_active_filters

    # Re-filter category chips based on admin subcategory settings
    if @filter_config.present?
      show_subcategories = @filter_config["show_subcategories"]
      filters.reject! do |f|
        next false unless f[:param] == "category_ids"
        cat = Category.find_by(id: f[:value])
        cat && cat.parent_id.present? && !show_subcategories
      end
    end

    filters
  end
end
