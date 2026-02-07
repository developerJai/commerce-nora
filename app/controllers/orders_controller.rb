class OrdersController < ApplicationController
  before_action :require_customer

  def index
    base_scope = current_customer.orders.placed.recent.includes(:order_items)

    @status = params[:status].to_s
    allowed_statuses = Order::STATUSES

    orders_scope = case @status
    when ''
      base_scope
    when 'not_shipped'
      base_scope.where(status: %w[pending confirmed processing])
    else
      allowed_statuses.include?(@status) ? base_scope.where(status: @status) : base_scope
    end

    @pagy, @orders = pagy(orders_scope, limit: 10)
  end

  def show
    @order = current_customer.orders.find_by!(order_number: params[:order_number])
    @order_items = @order.order_items.includes(product_variant: [:product])
    @can_review = @order.can_review?
    @reviewed_variants = @order.reviews.pluck(:product_id)
  end

  def cancel
    @order = current_customer.orders.find_by!(order_number: params[:order_number])

    reason = params[:cancellation_reason].to_s.strip
    if reason.blank?
      redirect_to order_path(@order), alert: "Please select a reason for cancellation."
      return
    end

    if @order.cancel!(reason: reason)
      redirect_to order_path(@order), notice: "Order has been cancelled successfully."
    else
      redirect_to order_path(@order), alert: "This order cannot be cancelled."
    end
  end
end
