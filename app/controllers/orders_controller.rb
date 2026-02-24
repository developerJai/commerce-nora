class OrdersController < ApplicationController
  before_action :require_customer

  require "prawn"
  require "prawn/table"

  def index
    base_scope = current_customer.orders.placed.recent.includes(:order_items)

    @status = params[:status].to_s
    allowed_statuses = Order::STATUSES

    orders_scope = case @status
    when ""
      base_scope
    when "not_shipped"
      base_scope.where(status: %w[pending confirmed processing])
    else
      allowed_statuses.include?(@status) ? base_scope.where(status: @status) : base_scope
    end

    @pagy, @orders = pagy(orders_scope, limit: 10)
  end

  def show
    @order = current_customer.orders.find_by!(order_number: params[:order_number])
    @order_items = @order.order_items.includes(product_variant: [ :product ])
    @can_review = @order.can_review?
    @reviewed_variants = @order.reviews.pluck(:product_id)
  end

  def cancel
    @order = current_customer.orders.find_by!(order_number: params[:order_number])
    reason = params[:cancellation_reason]

    if @order.can_cancel?
      if @order.cancel!(reason: reason)
        redirect_to order_path(@order), notice: "Order cancelled successfully."
      else
        redirect_to order_path(@order), alert: "Unable to cancel order."
      end
    else
      redirect_to order_path(@order), alert: "This order cannot be cancelled."
    end
  end

  # Deprecated: Use InvoicesController#show instead
  # Redirects to the unified invoice endpoint
  def download_invoice
    @order = current_customer.orders.find_by!(order_number: params[:order_number])
    redirect_to invoice_path(@order.order_number)
  end

  private
end
