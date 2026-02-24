module Admin
  class CheckoutSessionsController < BaseController
    before_action :set_checkout_session, only: [ :show, :analytics ]
    before_action :authorize_admin_access!

    def index
      checkout_sessions = CheckoutSession.includes(:customer, orders: [ :vendor ])
                                         .order(created_at: :desc)

      # Filter by status
      if params[:status].present?
        checkout_sessions = checkout_sessions.where(status: params[:status])
      end

      # Filter by payment method
      if params[:payment_method].present?
        checkout_sessions = checkout_sessions.where(payment_method: params[:payment_method])
      end

      # Date range filter
      if params[:start_date].present? && params[:end_date].present?
        checkout_sessions = checkout_sessions.where(
          created_at: params[:start_date]..params[:end_date]
        )
      end

      @pagy, @checkout_sessions = pagy(checkout_sessions, limit: 20)

      # Analytics summary
      @analytics = calculate_analytics
    end

    def show
      @orders = @checkout_session.orders.includes(:vendor, :customer, order_items: :product_variant)
    end

    def analytics
      @orders_by_status = @checkout_session.orders.group(:status).count
      @orders_by_vendor = @checkout_session.orders.joins(:vendor)
                                           .group("vendors.business_name")
                                           .count
      @payment_logs = PaymentLog.where(order_id: @checkout_session.orders.pluck(:id))
                                .order(created_at: :desc)
    end

    private

    def set_checkout_session
      @checkout_session = CheckoutSession.find(params[:id])
    end

    def authorize_admin_access!
      unless admin_role? || (vendor_context? && @checkout_session.orders.exists?(vendor: current_vendor))
        redirect_to admin_root_path, alert: "You don't have access to this checkout session."
      end
    end

    def calculate_analytics
      base_scope = CheckoutSession.all

      if params[:start_date].present? && params[:end_date].present?
        base_scope = base_scope.where(created_at: params[:start_date]..params[:end_date])
      else
        base_scope = base_scope.where("created_at >= ?", 30.days.ago)
      end

      {
        total_sessions: base_scope.count,
        successful: base_scope.where(status: "paid").count,
        failed: base_scope.where(status: "failed").count,
        pending: base_scope.where(status: "pending").count,
        refunded: base_scope.where(status: [ "refunded", "partially_refunded" ]).count,
        conversion_rate: calculate_conversion_rate(base_scope),
        total_revenue: base_scope.where(status: "paid").sum(:total_amount),
        total_refunded: base_scope.where(status: [ "refunded", "partially_refunded" ]).sum(:total_amount)
      }
    end

    def calculate_conversion_rate(scope)
      total = scope.count
      return 0 if total == 0

      successful = scope.where(status: "paid").count
      (successful.to_f / total * 100).round(2)
    end
  end
end
