module Admin
  class ProductVariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: [:edit, :update, :destroy, :toggle_status, :update_stock]

    def index
      @variants = @product.variants.ordered
    end

    def new
      @variant = @product.variants.build
    end

    def create
      @variant = @product.variants.build(variant_params)

      if @variant.save
        redirect_to admin_product_path(@product), notice: "Variant created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @variant.update(variant_params)
        redirect_to admin_product_path(@product), notice: "Variant updated successfully"
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
      redirect_to admin_product_path(@product), notice: "Variant #{@variant.active? ? 'enabled' : 'disabled'}"
    end

    def update_stock
      stock = params[:stock_quantity].to_i
      if @variant.update(stock_quantity: stock)
        redirect_to admin_product_path(@product), notice: "Stock updated"
      else
        redirect_to admin_product_path(@product), alert: "Failed to update stock"
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
      params.require(:product_variant).permit(
        :name, :sku, :price, :compare_at_price, :stock_quantity,
        :weight, :active, :position, :image
      )
    end
  end
end
