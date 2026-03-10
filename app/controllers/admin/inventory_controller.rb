module Admin
  class InventoryController < BaseController
    def index
      @filter = params[:filter] || 'all'
      @vendor_id = params[:vendor_id]
      
      base_variants = if vendor_context?
        ProductVariant.active.joins(:product).where(products: { vendor_id: current_vendor.id })
      else
        variants = ProductVariant.active
        if admin_role? && @vendor_id.present?
          variants = variants.joins(:product).where(products: { vendor_id: @vendor_id })
        end
        variants
      end

      variants = base_variants.includes(:product, image_attachment: :blob)
      
      variants = case @filter
      when 'out_of_stock'
        variants.out_of_stock
      when 'low_stock'
        variants.low_stock
      when 'needs_reorder'
        variants.needs_reorder
      else
        variants
      end

      if params[:q].present?
        variants = variants.joins(:product).where(
          "products.name ILIKE :q OR product_variants.name ILIKE :q OR product_variants.sku ILIKE :q",
          q: "%#{params[:q]}%"
        )
      end

      variants = variants.order('product_variants.stock_quantity ASC')
      @pagy, @variants = pagy(variants, limit: 25)

      # Stats
      @total_variants = base_variants.count
      @out_of_stock_count = base_variants.out_of_stock.count
      @low_stock_count = base_variants.low_stock.count
      @needs_reorder_count = base_variants.needs_reorder.count

      if admin_role? && !vendor_context?
        @vendors = Vendor.ordered
      end
    end

    def adjustments
      @variant = ProductVariant.find(params[:id]) if params[:id].present?
      
      adjustments = StockAdjustment.includes(product_variant: :product).recent
      adjustments = adjustments.where(product_variant_id: params[:id]) if params[:id].present?
      adjustments = adjustments.by_reason(params[:reason]) if params[:reason].present?
      
      @pagy, @adjustments = pagy(adjustments, limit: 30)
    end

    def adjust
      @variant = find_variant(params[:id])
    end

    def create_adjustment
      @variant = find_variant(params[:id])
      
      quantity_change = params[:quantity_change].to_i
      reason = params[:reason]
      notes = params[:notes]
      
      begin
        @variant.adjust_stock!(quantity_change, reason: reason, notes: notes, adjusted_by: current_admin)
        redirect_to admin_inventory_index_path, notice: "Stock adjusted successfully. New quantity: #{@variant.stock_quantity}"
      rescue => e
        flash.now[:alert] = e.message
        render :adjust, status: :unprocessable_entity
      end
    end

    def bulk_adjust
      base = if vendor_context?
        ProductVariant.active.joins(:product).where(products: { vendor_id: current_vendor.id })
      else
        ProductVariant.active
      end
      @variants = base.needs_reorder.includes(:product).order('stock_quantity ASC')
    end

    def create_bulk_adjustment
      success_count = 0
      error_messages = []

      params[:adjustments]&.each do |variant_id, data|
        next if data[:quantity].blank? || data[:quantity].to_i == 0

        variant = ProductVariant.find_by(id: variant_id)
        next unless variant

        begin
          variant.adjust_stock!(
            data[:quantity].to_i,
            reason: data[:reason] || 'restock',
            notes: data[:notes],
            adjusted_by: current_admin
          )
          success_count += 1
        rescue => e
          error_messages << "#{variant.display_name}: #{e.message}"
        end
      end

      if error_messages.any?
        redirect_to bulk_adjust_admin_inventory_index_path, alert: "#{success_count} items updated. Errors: #{error_messages.join(', ')}"
      else
        redirect_to admin_inventory_index_path, notice: "#{success_count} items restocked successfully"
      end
    end

    def reorder_report
      base = if vendor_context?
        ProductVariant.active.joins(:product).where(products: { vendor_id: current_vendor.id })
      else
        ProductVariant.active
      end
      @variants = base.needs_reorder.includes(:product).order('stock_quantity ASC')
      
      respond_to do |format|
        format.html
        format.csv do
          send_data generate_reorder_csv, filename: "reorder-report-#{Date.current}.csv"
        end
      end
    end

    private

    def find_variant(id)
      if vendor_context?
        ProductVariant.joins(:product).where(products: { vendor_id: current_vendor.id }).find(id)
      else
        ProductVariant.find(id)
      end
    end

    def generate_reorder_csv
      require 'csv'
      
      CSV.generate(headers: true) do |csv|
        csv << ['SKU', 'Product', 'Variant', 'Current Stock', 'Reorder Point', 'Suggested Reorder Qty', 'Estimated Cost']
        
        @variants.each do |v|
          estimated_cost = v.price * v.reorder_quantity * 0.6
          csv << [v.sku, v.product.name, v.name, v.stock_quantity, v.reorder_point, v.reorder_quantity, estimated_cost]
        end
      end
    end
  end
end
