module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [:show, :edit, :update, :confirm, :process_order, :ship, :deliver, :cancel]

    def index
      @status = params[:status]
      orders = Order.placed.includes(:customer).recent
      orders = orders.by_status(@status) if @status.present?
      @pagy, @orders = pagy(orders, limit: 20)
    end

    def drafts
      @pagy, @orders = pagy(Order.draft.includes(:customer).recent, limit: 20)
    end

    def show
      @order_items = @order.order_items.includes(:product_variant)
    end

    def edit
    end

    def update
      if @order.update(order_params)
        redirect_to admin_order_path(@order), notice: "Order updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def confirm
      @order.confirm!
      redirect_to admin_order_path(@order), notice: "Order confirmed"
    end

    def process_order
      @order.process!
      redirect_to admin_order_path(@order), notice: "Order is being processed"
    end

    def ship
      @order.ship!
      redirect_to admin_order_path(@order), notice: "Order shipped"
    end

    def deliver
      @order.deliver!
      redirect_to admin_order_path(@order), notice: "Order delivered"
    end

    def cancel
      if @order.cancel!
        redirect_to admin_order_path(@order), notice: "Order cancelled"
      else
        redirect_to admin_order_path(@order), alert: "Cannot cancel this order"
      end
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.require(:order).permit(:admin_notes, :status, :payment_status)
    end
  end
end
