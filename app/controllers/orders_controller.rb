class OrdersController < ApplicationController
  before_action :require_customer

  def index
    @pagy, @orders = pagy(current_customer.orders.placed.recent.includes(:order_items), items: 10)
  end

  def show
    @order = current_customer.orders.find(params[:id])
    @order_items = @order.order_items.includes(product_variant: [:product])
    @can_review = @order.can_review?
    @reviewed_variants = @order.reviews.pluck(:product_id)
  end
end
