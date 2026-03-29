class VendorStorefrontsController < ApplicationController
  include ProductFiltering

  def show
    @vendor = Vendor.active.find_by!(slug: params[:slug])

    # Track entry point for "back to vendor" flow
    session[:vendor_storefront_slug] = @vendor.slug

    # Parse filter params from concern
    parse_filter_params

    # Vendor-scoped product base
    vendor_products = Product.active.where(vendor_id: @vendor.id)

    # Catalog price bounds (vendor-scoped)
    vendor_variant_scope = ProductVariant.where(active: true)
                             .where(product_id: vendor_products.select(:id))
    @catalog_min_price = vendor_variant_scope.minimum(:price).to_f.floor
    @catalog_max_price = vendor_variant_scope.maximum(:price).to_f.ceil

    # Build base product IDs with non-multiselect filters
    base_product_ids = build_filtered_product_ids(
      base_scope: vendor_products,
      category_ids: @category_ids,
      rating: @rating,
      in_stock: @in_stock,
      min_price: @min_price,
      max_price: @max_price,
      discount: @discount,
      q: @q
    )

    # Facets
    @facets = build_facets_from_ids(base_product_ids, @in_stock)

    # Categories this vendor has products in
    vendor_category_ids = vendor_products.distinct.pluck(:category_id).compact
    @vendor_categories = Category.active.where(id: vendor_category_ids).ordered

    # Category counts (without category filter applied)
    category_count_ids = build_filtered_product_ids(
      base_scope: vendor_products,
      category_ids: [],
      rating: @rating,
      in_stock: @in_stock,
      min_price: @min_price,
      max_price: @max_price,
      discount: @discount,
      q: @q
    )
    @category_counts = Product.where(id: category_count_ids).group(:category_id).count

    # Apply multiselect filters
    final_product_ids = apply_multiselect_filters(
      base_product_ids,
      colors: @colors,
      materials: @materials,
      gemstones: @gemstones,
      occasions: @occasions,
      in_stock: @in_stock
    )

    # Sort and paginate
    products = build_sorted_products(final_product_ids, @sort, @in_stock)

    per_page = helpers.mobile_request? ? 16 : 15
    @pagy, @products = pagy(products, limit: per_page, count: final_product_ids.length)

    @active_filters = build_active_filters

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
