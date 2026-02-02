module Admin
  class ReportsController < BaseController
    def index
      @start_date = params[:start_date]&.to_date || 30.days.ago.to_date
      @end_date = params[:end_date]&.to_date || Date.current

      @total_orders = orders_in_range.count
      @total_revenue = orders_in_range.sum(:total_amount)
      @average_order_value = @total_orders > 0 ? @total_revenue / @total_orders : 0

      @orders_by_status = Order.placed.where(placed_at: @start_date..@end_date.end_of_day)
                               .group(:status).count

      @daily_revenue = Order.placed.where(placed_at: @start_date..@end_date.end_of_day)
                            .group("DATE(placed_at)").sum(:total_amount)
    end

    def sales
      @start_date = params[:start_date]&.to_date || 30.days.ago.to_date
      @end_date = params[:end_date]&.to_date || Date.current

      @orders = orders_in_range.includes(:customer, :order_items)

      @daily_sales = orders_in_range.group("DATE(placed_at)")
                                    .select("DATE(placed_at) as date, COUNT(*) as orders_count, SUM(total_amount) as revenue")
                                    .order("date DESC")
    end

    def products
      @start_date = params[:start_date]&.to_date || 30.days.ago.to_date
      @end_date = params[:end_date]&.to_date || Date.current

      @top_products = OrderItem.joins(:order)
                               .where(orders: { placed_at: @start_date..@end_date.end_of_day, is_draft: false })
                               .group(:product_name)
                               .select("product_name, SUM(quantity) as total_quantity, SUM(total_price) as total_revenue")
                               .order("total_revenue DESC")
                               .limit(20)

      @low_stock = ProductVariant.where("stock_quantity < ?", 10)
                                 .includes(:product)
                                 .order(:stock_quantity)
    end

    def customers
      @start_date = params[:start_date]&.to_date || 30.days.ago.to_date
      @end_date = params[:end_date]&.to_date || Date.current

      @new_customers = Customer.where(created_at: @start_date..@end_date.end_of_day).count

      @top_customers = Customer.joins(:orders)
                               .where(orders: { placed_at: @start_date..@end_date.end_of_day, is_draft: false })
                               .group("customers.id")
                               .select("customers.*, COUNT(orders.id) as orders_count, SUM(orders.total_amount) as total_spent")
                               .order("total_spent DESC")
                               .limit(20)
    end

    private

    def orders_in_range
      Order.placed.where(placed_at: @start_date..@end_date.end_of_day)
    end
  end
end
