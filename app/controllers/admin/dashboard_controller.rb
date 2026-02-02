module Admin
  class DashboardController < BaseController
    def index
      @total_orders = Order.placed.count
      @total_revenue = Order.placed.sum(:total_amount)
      @total_customers = Customer.count
      @total_products = Product.count

      @recent_orders = Order.placed.recent.includes(:customer).limit(5)
      @pending_orders = Order.placed.where(status: 'pending').count
      @low_stock_products = ProductVariant.where("stock_quantity < ?", 10).count
      @open_tickets = SupportTicket.open_tickets.count

      @orders_today = Order.placed.where("placed_at >= ?", Time.current.beginning_of_day).count
      @revenue_today = Order.placed.where("placed_at >= ?", Time.current.beginning_of_day).sum(:total_amount)

      @orders_this_month = Order.placed.where("placed_at >= ?", Time.current.beginning_of_month).count
      @revenue_this_month = Order.placed.where("placed_at >= ?", Time.current.beginning_of_month).sum(:total_amount)
    end
  end
end
