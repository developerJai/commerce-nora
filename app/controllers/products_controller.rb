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

    # ── Base query ───────────────────────────────────────────────────
    products = Product.active.includes(
      :category,
      { variants: { image_attachment: :blob } },
      images_attachments: :blob
    )

    # ── Apply category filter ────────────────────────────────────────
    if @category_ids.any?
      # Expand selected categories to include the full family tree:
      # - Selecting a parent includes products on the parent + all its children
      # - Selecting any child also includes products assigned directly to its parent
      #   (since a product under "Jewellery" logically belongs to all subcategories)
      selected_categories = Category.where(id: @category_ids).includes(:children, :parent)
      expanded_ids = selected_categories.flat_map { |cat|
        ids = cat.self_and_children_ids
        ids << cat.parent_id if cat.parent_id.present?
        ids
      }.compact.uniq
      products = products.where(category_id: expanded_ids)
    end

    # ── Apply price filter ───────────────────────────────────────────
    if @min_price.present? || @max_price.present?
      price_filter = ProductVariant.where(active: true).group(:product_id)
      price_filter = price_filter.having("MIN(price) >= ?", @min_price.to_f) if @min_price.present?
      price_filter = price_filter.having("MIN(price) <= ?", @max_price.to_f) if @max_price.present?
      products = products.where(id: price_filter.select(:product_id))
    end

    # ── Faceted counts (from base filtered set, before multiselect filters) ──
    # Build facets before applying color/material/gemstone/occasion filters
    # so that all options remain visible for multiselect support
    @facets = build_facets(products)

    # ── Apply multiselect filters (color, material, gemstone, occasion) ─────
    products = products.by_color(@colors) if @colors.any?
    products = products.by_attribute(:base_material, @materials) if @materials.any?
    products = products.by_attribute(:gemstone, @gemstones) if @gemstones.any?
    products = products.by_attribute(:occasion, @occasions) if @occasions.any?

    # ── Apply remaining filters ──────────────────────────────────────
    products = products.by_discount(@discount) if @discount.present?
    products = products.by_rating(@rating) if @rating.present?
    products = products.in_stock_only if @in_stock

    # ── Sort ─────────────────────────────────────────────────────────
    products = case @sort
    when "price_low"
      products.left_joins(:variants).where(product_variants: { active: true }).group(:id).order("MIN(product_variants.price) ASC")
    when "price_high"
      products.left_joins(:variants).where(product_variants: { active: true }).group(:id).order("MIN(product_variants.price) DESC")
    when "rating"
      products.order(average_rating: :desc)
    when "discount"
      products.left_joins(:variants)
              .where(product_variants: { active: true })
              .where("product_variants.compare_at_price > product_variants.price")
              .group(:id)
              .order(Arel.sql("MAX((product_variants.compare_at_price - product_variants.price) / NULLIF(product_variants.compare_at_price, 0) * 100) DESC"))
    else
      products.order(created_at: :desc)
    end

    @pagy, @products = pagy(products, limit: 16)
    @category_counts = Product.active.group(:category_id).count
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
end
