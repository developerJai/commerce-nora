module Admin
  class DraftOrdersController < BaseController
    before_action :set_order, only: [:show, :edit, :update, :destroy, :convert_to_order]

    def index
      @pagy, @draft_orders = pagy(Order.draft.includes(:customer).recent, limit: 20)
    end

    def show
      @order_items = @order.order_items.includes(:product_variant)
    end

    def new
      @order = Order.new(is_draft: true)
      @customers = Customer.active.order(:first_name)
      @variants = ProductVariant.active.in_stock.includes(:product).order("products.name")
    end

    def create
      @order = Order.new(draft_order_params)
      @order.is_draft = true

      if @order.save
        redirect_to admin_draft_order_path(@order), notice: "Draft order created"
      else
        @customers = Customer.active.order(:first_name)
        @variants = ProductVariant.active.in_stock.includes(:product)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @customers = Customer.active.order(:first_name)
      @variants = ProductVariant.active.in_stock.includes(:product)
    end

    def update
      if @order.update(draft_order_params)
        redirect_to admin_draft_order_path(@order), notice: "Draft order updated"
      else
        @customers = Customer.active.order(:first_name)
        @variants = ProductVariant.active.in_stock.includes(:product)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @order.destroy
      redirect_to admin_draft_orders_path, notice: "Draft order deleted"
    end

    def convert_to_order
      if @order.place!
        redirect_to admin_order_path(@order), notice: "Draft order converted to order"
      else
        redirect_to admin_draft_order_path(@order), alert: @order.errors.full_messages.join(", ")
      end
    end

    private

    def set_order
      @order = Order.draft.find(params[:id])
    end

    def draft_order_params
      params.require(:order).permit(
        :customer_id, :shipping_address_id, :billing_address_id,
        :notes, :admin_notes, :coupon_id,
        order_items_attributes: [:id, :product_variant_id, :quantity, :unit_price, :_destroy]
      )
    end
  end
end
