module ProductFiltering
  extend ActiveSupport::Concern

  private

  def parse_filter_params
    @category_ids = Array(params[:category_ids]).reject(&:blank?)
    @min_price    = params[:min_price]
    @max_price    = params[:max_price]
    @sort         = params[:sort].presence || "newest"
    @colors       = Array(params[:colors]).reject(&:blank?)
    @materials    = Array(params[:materials]).reject(&:blank?)
    @gemstones    = Array(params[:gemstones]).reject(&:blank?)
    @occasions    = Array(params[:occasions]).reject(&:blank?)
    @discount     = params[:discount]
    @rating       = params[:rating]
    @in_stock     = params[:in_stock] == "1"
    @q            = params[:q].to_s.strip
  end

  # Build filtered product IDs with non-multiselect filters
  # base_scope: starting scope (e.g. Product.active or Product.active.where(vendor_id: x))
  def build_filtered_product_ids(base_scope: Product.active, category_ids:, rating:, in_stock:, min_price:, max_price:, discount:, q: nil)
    products = base_scope

    # Search query filter
    products = products.search(q) if q.present?

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

      if in_stock
        products = products.where("product_variants.stock_quantity > ?", 0)
      end

      products = products.where("product_variants.price >= ?", min_price.to_f) if min_price.present?
      products = products.where("product_variants.price <= ?", max_price.to_f) if max_price.present?

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

    color_query = products.joins(:variants)
                          .where(product_variants: { active: true })
                          .where.not(product_variants: { color: [ nil, "" ] })
    color_query = color_query.where("product_variants.stock_quantity > ?", 0) if in_stock
    colors = color_query.group("product_variants.color").count

    materials = products.where.not(base_material: [ nil, "" ]).group(:base_material).count
    gemstones = products.where.not(gemstone: [ nil, "" ]).group(:gemstone).count
    occasions = products.where.not(occasion: [ nil, "" ]).group(:occasion).count

    { colors: colors, materials: materials, gemstones: gemstones, occasions: occasions }
  end

  # Apply multiselect filters (color, material, gemstone, occasion)
  def apply_multiselect_filters(product_ids, colors:, materials:, gemstones:, occasions:, in_stock:)
    return product_ids if product_ids.empty?

    products = Product.where(id: product_ids)

    if colors.any?
      color_query = products.joins(:variants)
                            .where(product_variants: { active: true, color: colors })
      color_query = color_query.where("product_variants.stock_quantity > ?", 0) if in_stock
      products = color_query.distinct
    end

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

    products.includes(
      :category,
      { variants: { image_attachment: :blob } },
      images_attachments: :blob
    )
  end

  def build_active_filters
    filters = []

    if @q.present?
      filters << { label: "Search: #{@q}", param: "q", value: @q }
    end

    @category_ids.each do |cid|
      cat = Category.find_by(id: cid)
      next unless cat
      filters << { label: cat.name, param: "category_ids", value: cid }
    end

    @colors.each { |v| filters << { label: "Color: #{v}", param: "colors", value: v } }
    @materials.each { |v| filters << { label: "Material: #{v}", param: "materials", value: v } }
    @gemstones.each { |v| filters << { label: "Stone: #{v}", param: "gemstones", value: v } }
    @occasions.each { |v| filters << { label: "Occasion: #{v}", param: "occasions", value: v } }
    filters << { label: "#{@discount}%+ Off", param: "discount", value: @discount } if @discount.present?
    filters << { label: "#{@rating}★ & above", param: "rating", value: @rating } if @rating.present?
    filters << { label: "In Stock", param: "in_stock", value: "1" } if @in_stock
    filters << { label: "Min ₹#{@min_price}", param: "min_price", value: @min_price } if @min_price.present?
    filters << { label: "Max ₹#{@max_price}", param: "max_price", value: @max_price } if @max_price.present?
    filters
  end
end
