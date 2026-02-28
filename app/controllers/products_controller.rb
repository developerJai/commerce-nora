class ProductsController < ApplicationController
  def index
    # ── Parse filter params ──────────────────────────────────────────
    @category_ids = Array(params[:category_ids]).reject(&:blank?)
    @min_price    = params[:min_price]
    @max_price    = params[:max_price]
    @sort         = params[:sort].presence || "rating"
    @colors       = Array(params[:colors]).reject(&:blank?)
    @materials    = Array(params[:materials]).reject(&:blank?)
    @gemstones    = Array(params[:gemstones]).reject(&:blank?)
    @occasions    = Array(params[:occasions]).reject(&:blank?)
    @discount     = params[:discount]
    @rating       = params[:rating]
    @in_stock     = params[:in_stock] == "1"

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
      discount: @discount
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
      discount: @discount
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

    @pagy, @products = pagy(products, limit: 16)
    @category_tree = Category.grouped_for_filters(product_counts: @category_counts)

    # ── Filter visibility (admin-configurable) ───────────────────────
    @filter_config = StoreSetting.instance.effective_filter_config

    # ── Active filters (for chips display) ───────────────────────────
    @active_filters = build_active_filters

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
    ).find_by!(slug: params[:slug])
    @variants = @product.variants.active.ordered
    @reviews = @product.approved_reviews.includes(:customer).recent.limit(10)
    @related_products = Product.active.where(category_id: @product.category_id)
                               .where.not(id: @product.id)
                               .includes({ variants: { image_attachment: :blob } }, images_attachments: :blob)
                               .limit(4)

    @selected_variant = if params[:variant].present?
      @variants.find { |v| v.name.parameterize == params[:variant] } || @variants.first
    else
      @variants.first
    end

    @cart_item = @selected_variant ? current_cart.cart_items.find_by(product_variant: @selected_variant) : nil
  end

  private

  def build_facets(products)
    {
      colors: products.available_colors,
      materials: products.available_filter_values(:base_material),
      gemstones: products.available_filter_values(:gemstone),
      occasions: products.available_filter_values(:occasion)
    }
  end

  def build_active_filters
    filters = []
    @category_ids.each do |cid|
      cat = Category.find_by(id: cid)
      filters << { label: cat.name, param: "category_ids", value: cid } if cat
    end
    @colors.each { |v| filters << { label: "Color: #{v}", param: "colors", value: v } }
    @materials.each { |v| filters << { label: "Material: #{v}", param: "materials", value: v } }
    @gemstones.each { |v| filters << { label: "Stone: #{v}", param: "gemstones", value: v } }
    @occasions.each { |v| filters << { label: "Occasion: #{v}", param: "occasions", value: v } }
    filters << { label: "#{@discount}%+ Off", param: "discount", value: @discount } if @discount.present?
    filters << { label: "#{@rating}★ & above", param: "rating", value: @rating } if @rating.present?
    filters << { label: "In Stock", param: "in_stock", value: "1" } if @in_stock
    if @min_price.present?
      filters << { label: "Min ₹#{@min_price}", param: "min_price", value: @min_price }
    end
    if @max_price.present?
      filters << { label: "Max ₹#{@max_price}", param: "max_price", value: @max_price }
    end
    filters
  end

  # Build filtered product IDs with non-multiselect filters
  # This is the base for facet calculation
  def build_filtered_product_ids(category_ids:, rating:, in_stock:, min_price:, max_price:, discount:)
    products = Product.active

    # Category filter
    if category_ids.any?
      selected_categories = Category.where(id: category_ids).includes(:children, :parent)
      expanded_ids = selected_categories.flat_map { |cat|
        ids = cat.self_and_children_ids
        ids << cat.parent_id if cat.parent_id.present?
        ids
      }.compact.uniq
      products = products.where(category_id: expanded_ids)
    end

    # Rating filter (product-level)
    products = products.where("average_rating >= ?", rating.to_f) if rating.present? && rating.to_f > 0

    # Variant-level filters require joining variants
    needs_variant_filter = in_stock || min_price.present? || max_price.present? || discount.present?

    if needs_variant_filter
      products = products.joins(:variants).where(product_variants: { active: true })

      # In-stock filter
      if in_stock
        products = products.where("product_variants.stock_quantity > ?", 0)
      end

      # Price range filter
      products = products.where("product_variants.price >= ?", min_price.to_f) if min_price.present?
      products = products.where("product_variants.price <= ?", max_price.to_f) if max_price.present?

      # Discount filter
      if discount.present?
        products = products.where("product_variants.compare_at_price > product_variants.price")
                           .where("((product_variants.compare_at_price - product_variants.price) / product_variants.compare_at_price * 100) >= ?", discount.to_i)
      end

      products = products.distinct
    end

    products.pluck(:id)
  end

  # Build facets from product IDs (respects in-stock filter for variant colors)
  def build_facets_from_ids(product_ids, in_stock)
    return { colors: {}, materials: {}, gemstones: {}, occasions: {} } if product_ids.empty?

    products = Product.where(id: product_ids)

    # For colors, we need to respect in-stock filter at variant level
    color_query = products.joins(:variants)
                          .where(product_variants: { active: true })
                          .where.not(product_variants: { color: [nil, ""] })
    color_query = color_query.where("product_variants.stock_quantity > ?", 0) if in_stock
    colors = color_query.group("product_variants.color").count

    # Product-level attributes
    materials = products.where.not(base_material: [nil, ""]).group(:base_material).count
    gemstones = products.where.not(gemstone: [nil, ""]).group(:gemstone).count
    occasions = products.where.not(occasion: [nil, ""]).group(:occasion).count

    { colors: colors, materials: materials, gemstones: gemstones, occasions: occasions }
  end

  # Apply multiselect filters (color, material, gemstone, occasion)
  def apply_multiselect_filters(product_ids, colors:, materials:, gemstones:, occasions:, in_stock:)
    return product_ids if product_ids.empty?

    products = Product.where(id: product_ids)

    # Color filter (variant-level)
    if colors.any?
      color_query = products.joins(:variants)
                            .where(product_variants: { active: true, color: colors })
      color_query = color_query.where("product_variants.stock_quantity > ?", 0) if in_stock
      products = color_query.distinct
    end

    # Product-level attribute filters
    products = products.where(base_material: materials) if materials.any?
    products = products.where(gemstone: gemstones) if gemstones.any?
    products = products.where(occasion: occasions) if occasions.any?

    products.pluck(:id)
  end

  # Build sorted products query with eager loading
  def build_sorted_products(product_ids, sort, in_stock)
    return Product.none if product_ids.empty?

    products = case sort
    when "price_low", "price_high"
      direction = sort == "price_low" ? "ASC" : "DESC"
      query = Product.where(id: product_ids)
                     .joins(:variants)
                     .where(product_variants: { active: true })
      query = query.where("product_variants.stock_quantity > ?", 0) if in_stock
      query.group("products.id")
           .order(Arel.sql("MIN(product_variants.price) #{direction}"))
    when "rating"
      Product.where(id: product_ids)
             .order(Arel.sql("COALESCE(average_rating, 0) DESC"))
    when "discount"
      query = Product.where(id: product_ids)
                     .joins(:variants)
                     .where(product_variants: { active: true })
      query = query.where("product_variants.stock_quantity > ?", 0) if in_stock
      query.group("products.id")
           .order(Arel.sql(
             "MAX(CASE " \
             "WHEN product_variants.compare_at_price > product_variants.price " \
             "THEN (product_variants.compare_at_price - product_variants.price) / NULLIF(product_variants.compare_at_price, 0) * 100 " \
             "ELSE 0 END) DESC"
           ))
    when "newest"
      Product.where(id: product_ids)
             .order(created_at: :desc)
    else
      Product.where(id: product_ids)
             .order(Arel.sql("COALESCE(average_rating, 0) DESC"))
    end

    # Eager load associations for display
    products.includes(
      :category,
      { variants: { image_attachment: :blob } },
      images_attachments: :blob
    )
  end
end
