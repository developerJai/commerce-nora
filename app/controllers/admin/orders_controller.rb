module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [ :show, :edit, :update, :confirm, :process_order, :ship, :deliver, :cancel, :rollback, :initiate_refund, :mark_refund_paid, :mark_refund_failed, :download_customer_invoice, :download_vendor_invoice ]

    require "prawn"
    require "prawn/table"

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
        pending: base_orders.where(status: "pending").count,
        confirmed: base_orders.where(status: "confirmed").count,
        processing: base_orders.where(status: "processing").count,
        shipped: base_orders.where(status: "shipped").count,
        delivered: base_orders.where(status: "delivered").count,
        cancelled: base_orders.where(status: "cancelled").count
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

    def refunds
      base_orders = vendor_scoped(Order).placed

      @refund_counts = {
        initiated: base_orders.where(refund_status: "initiated").count,
        paid: base_orders.where(refund_status: "paid").count,
        failed: base_orders.where(refund_status: "failed").count,
        all: base_orders.where.not(refund_status: "not_refunded").count
      }

      orders = base_orders.where.not(refund_status: "not_refunded")
      orders = orders.where(refund_status: params[:status]) if params[:status].present?
      @pagy, @orders = pagy(orders.includes(:customer).recent, limit: 20)
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
      reason = params[:cancellation_reason]

      if @order.cancel!(reason: reason)
        # For online payments, automatically initiate refund
        if @order.razorpay? && @order.paid?
          @order.initiate_refund!(
            amount: @order.total_amount,
            transaction_id: nil,
            remarks: "Auto-initiated after order cancellation",
            processed_by: current_admin&.id
          )
          redirect_to admin_order_path(@order), notice: "Order cancelled successfully. Refund has been auto-initiated and is pending payment."
        else
          redirect_to admin_order_path(@order), notice: "Order cancelled successfully"
        end
      else
        redirect_to admin_order_path(@order), alert: "Cannot cancel this order"
      end
    end

    def rollback
      unless @order.can_rollback?
        redirect_to admin_order_path(@order), alert: @order.errors.full_messages.join(", ") || "Cannot move order back from this status"
        return
      end

      @order.rollback!
      redirect_to admin_order_path(@order), notice: "Order moved back"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_order_path(@order), alert: e.message || "Cannot move order back from this status"
    end

    # Refund actions
    def initiate_refund
      unless @order.eligible_for_refund_initiation?
        redirect_to admin_order_path(@order), alert: "Order is not eligible for refund initiation"
        return
      end

      amount = params[:refund_amount].present? ? params[:refund_amount].to_d : @order.total_amount

      if @order.initiate_refund!(
        amount: amount,
        transaction_id: params[:refund_transaction_id],
        remarks: params[:refund_remarks],
        processed_by: current_admin&.id
      )
        redirect_to admin_order_path(@order), notice: "Refund initiated successfully"
      else
        redirect_to admin_order_path(@order), alert: @order.errors.full_messages.join(", ")
      end
    end

    def mark_refund_paid
      unless @order.eligible_for_mark_refund_paid?
        redirect_to admin_order_path(@order), alert: "Refund cannot be marked as paid"
        return
      end

      if @order.mark_refund_paid!(
        transaction_id: params[:refund_transaction_id],
        remarks: params[:refund_remarks]
      )
        redirect_to admin_order_path(@order), notice: "Refund marked as paid successfully"
      else
        redirect_to admin_order_path(@order), alert: @order.errors.full_messages.join(", ")
      end
    end

    def mark_refund_failed
      unless @order.refund_initiated?
        redirect_to admin_order_path(@order), alert: "No refund initiation to mark as failed"
        return
      end

      if @order.mark_refund_failed!(params[:error_message])
        redirect_to admin_order_path(@order), notice: "Refund marked as failed"
      else
        redirect_to admin_order_path(@order), alert: @order.errors.full_messages.join(", ")
      end
    end

    # Invoice download actions
    # Deprecated: Use InvoicesController#show instead
    def download_customer_invoice
      redirect_to invoice_path(@order.order_number)
    end

    # Deprecated: Use InvoicesController#show with view_as_vendor param
    def download_vendor_invoice
      unless @order.vendor.present?
        redirect_to admin_order_path(@order), alert: "No vendor associated with this order"
        return
      end

      redirect_to invoice_path(@order.order_number, view_as_vendor: true)
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
