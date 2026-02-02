module Admin
  class InventoryController < BaseController
    include Pagy::Backend

    def index
      @filter = params[:filter] || 'all'
      
      variants = ProductVariant.active.includes(:product, image_attachment: :blob)
      
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
      @pagy, @variants = pagy(variants, items: 25)

      # Stats
      @total_variants = ProductVariant.active.count
      @out_of_stock_count = ProductVariant.active.out_of_stock.count
      @low_stock_count = ProductVariant.active.low_stock.count
      @needs_reorder_count = ProductVariant.active.needs_reorder.count
    end

    def adjustments
      @variant = ProductVariant.find(params[:id]) if params[:id].present?
      
      adjustments = StockAdjustment.includes(product_variant: :product).recent
      adjustments = adjustments.where(product_variant_id: params[:id]) if params[:id].present?
      adjustments = adjustments.by_reason(params[:reason]) if params[:reason].present?
      
      @pagy, @adjustments = pagy(adjustments, items: 30)
    end

    def adjust
      @variant = ProductVariant.find(params[:id])
    end

    def create_adjustment
      @variant = ProductVariant.find(params[:id])
      
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
      @variants = ProductVariant.active.needs_reorder.includes(:product).order('stock_quantity ASC')
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
      @variants = ProductVariant.active.needs_reorder
                    .includes(:product)
                    .order('stock_quantity ASC')
      
      respond_to do |format|
        format.html
        format.csv do
          send_data generate_reorder_csv, filename: "reorder-report-#{Date.current}.csv"
        end
      end
    end

    private

    def generate_reorder_csv
      require 'csv'
      
      CSV.generate(headers: true) do |csv|
        csv << ['SKU', 'Product', 'Variant', 'Current Stock', 'Reorder Point', 'Suggested Reorder Qty']
        
        @variants.each do |v|
          csv << [v.sku, v.product.name, v.name, v.stock_quantity, v.reorder_point, v.reorder_quantity]
        end
      end
    end
  end
end
