module Admin
  class DashboardController < BaseController
    def index
      @total_orders = Order.placed.count
      @total_revenue = Order.placed.sum(:total_amount)
      @total_customers = Customer.count
      @total_products = Product.count

      @recent_orders = Order.placed.recent.includes(:customer).limit(5)
      @pending_orders = Order.placed.where(status: 'pending').count
      @confirmed_not_shipped_orders = Order.placed.where(status: %w[confirmed processing]).count
      @low_stock_products = ProductVariant.where("stock_quantity < ?", 10).count
      @unread_open_tickets = SupportTicket.open_tickets.unread_for_admin.count
      @open_tickets = SupportTicket.open_tickets.count
      @pending_reviews = Review.pending.count

      @orders_today = Order.placed.where("placed_at >= ?", Time.current.beginning_of_day).count
      @revenue_today = Order.placed.where("placed_at >= ?", Time.current.beginning_of_day).sum(:total_amount)

      @orders_this_month = Order.placed.where("placed_at >= ?", Time.current.beginning_of_month).count
      @revenue_this_month = Order.placed.where("placed_at >= ?", Time.current.beginning_of_month).sum(:total_amount)
    end
  end
end
