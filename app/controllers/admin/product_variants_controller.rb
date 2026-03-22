module Admin
  class ProductVariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: [ :show, :edit, :update, :destroy, :toggle_status, :update_stock ]

    def index
      @variants = @product.variants.ordered
    end

    def show
      @other_variants = @product.variants.where.not(id: @variant.id).ordered
      @stock_adjustments = @variant.stock_adjustments.order(created_at: :desc).limit(10)
    end

    def new
      @variant = @product.variants.build
    end

    def create
      @variant = @product.variants.build(variant_params)

      if @variant.save
        redirect_to admin_product_variant_path(@product, @variant), notice: "Variant created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @variant.update(variant_params)
        redirect_to admin_product_variant_path(@product, @variant), notice: "Variant updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @variant.destroy
      redirect_to admin_product_path(@product), notice: "Variant deleted successfully"
    end

    def toggle_status
      @variant.update(active: !@variant.active?)
      redirect_to admin_product_variant_path(@product, @variant), notice: "Variant #{@variant.active? ? 'enabled' : 'disabled'}"
    end

    def update_stock
      quantity_change = params[:quantity_change].to_i
      reason = params[:reason].presence || "correction"
      notes = params[:notes].presence

      begin
        @variant.adjust_stock!(quantity_change, reason: reason, notes: notes, adjusted_by: current_admin)
        redirect_to admin_product_variant_path(@product, @variant), notice: "Stock updated successfully"
      rescue => e
        redirect_to admin_product_variant_path(@product, @variant), alert: e.message
      end
    end

    private

    def set_product
      @product = vendor_scoped(Product).find(params[:product_id])
    end

    def set_variant
      @variant = @product.variants.find(params[:id])
    end

    def variant_params
      result = params.require(:product_variant).permit(
        :name, :sku, :price, :compare_at_price, :stock_quantity,
        :weight, :color, :size, :active, :position, :image,
        :track_inventory, :reorder_point, :reorder_quantity
      )

      if params[:product_variant][:properties].is_a?(ActionController::Parameters)
        result[:properties] = params[:product_variant][:properties].permit!.to_h
      end

      result
    end
  end
end
