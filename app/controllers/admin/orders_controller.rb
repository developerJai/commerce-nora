module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [:show, :edit, :update, :confirm, :process_order, :ship, :deliver, :cancel, :rollback]

    def index
      @status = params[:status]
      @not_shipped = params[:not_shipped]
      @vendor_id = params[:vendor_id]

      base_orders = vendor_scoped(Order).placed
      if admin_role? && !vendor_context? && @vendor_id.present?
        base_orders = base_orders.where(vendor_id: @vendor_id)
      end

      @order_counts = {
        all: base_orders.count,
        pending: base_orders.where(status: 'pending').count,
        confirmed: base_orders.where(status: 'confirmed').count,
        processing: base_orders.where(status: 'processing').count,
        shipped: base_orders.where(status: 'shipped').count,
        delivered: base_orders.where(status: 'delivered').count,
        cancelled: base_orders.where(status: 'cancelled').count
      }
      @not_shipped_count = base_orders.where(status: %w[confirmed processing]).count

      orders = base_orders.includes(:customer).recent
      orders = orders.where(status: %w[confirmed processing]) if @not_shipped.present?
      orders = orders.by_status(@status) if @status.present?
      @pagy, @orders = pagy(orders, limit: 20)

      if admin_role? && !vendor_context?
        @vendors = Vendor.ordered
      end
    end

    def drafts
      return redirect_to(admin_root_path, alert: "Access denied") if vendor_role?
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
      @order.assign_attributes(shipment_params)
      @order.ship!
      redirect_to admin_order_path(@order), notice: "Order shipped"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_order_path(@order), alert: e.record.errors.full_messages.join(", ")
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

    def rollback
      @order.rollback!
      redirect_to admin_order_path(@order), notice: "Order moved back"
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_order_path(@order), alert: "Cannot move order back from this status"
    end

    private

    def set_order
      @order = vendor_scoped(Order).find_by!(order_number: params[:order_number])
    end

    def order_params
      params.require(:order).permit(:admin_notes, :status, :payment_status)
    end

    def shipment_params
      return {} unless params[:order].present?
      params.require(:order).permit(:shipping_carrier, :tracking_number, :tracking_url, :shipper_name)
    end
  end
end
