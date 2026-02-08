module Admin
  class DashboardController < BaseController
    def index
      orders_scope = vendor_scoped(Order).placed
      products_scope = vendor_scoped(Product)

      @total_orders = orders_scope.count
      @total_revenue = orders_scope.sum(:total_amount)
      @total_products = products_scope.count

      @recent_orders = orders_scope.recent.includes(:customer).limit(5)
      @pending_orders = orders_scope.where(status: 'pending').count
      @confirmed_not_shipped_orders = orders_scope.where(status: %w[confirmed processing]).count

      @orders_today = orders_scope.where("placed_at >= ?", Time.current.beginning_of_day).count
      @revenue_today = orders_scope.where("placed_at >= ?", Time.current.beginning_of_day).sum(:total_amount)

      @orders_this_month = orders_scope.where("placed_at >= ?", Time.current.beginning_of_month).count
      @revenue_this_month = orders_scope.where("placed_at >= ?", Time.current.beginning_of_month).sum(:total_amount)

      if vendor_context?
        variant_ids = ProductVariant.where(product: products_scope).select(:id)
        vendor_variants = ProductVariant.where(id: variant_ids)
        @out_of_stock_variants_count = vendor_variants.out_of_stock.count
        @low_stock_variants_count = vendor_variants.low_stock.count
        @low_stock_products = vendor_variants.where("stock_quantity < ?", 10).count
        @open_tickets = SupportTicket.for_vendor(current_vendor).open_tickets.count
        @unread_open_tickets = SupportTicket.for_vendor(current_vendor).open_tickets.unread_for_admin.count
        @pending_reviews = Review.joins(:product).where(products: { vendor_id: current_vendor.id }).pending.count
      else
        @total_customers = Customer.count
        @low_stock_products = ProductVariant.where("stock_quantity < ?", 10).count
        @unread_open_tickets = SupportTicket.open_tickets.unread_for_admin.count
        @open_tickets = SupportTicket.open_tickets.count
        @pending_reviews = Review.pending.count

        @total_vendors = Vendor.count
        @low_inventory_vendors = Vendor.joins(products: :variants)
          .merge(ProductVariant.needs_reorder)
          .distinct
          .count
      end
    end
  end
end
