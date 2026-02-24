module Admin
  class VendorEarningsController < BaseController
    before_action :require_vendor_context
    before_action :set_vendor
    before_action :set_config

    def index
      @total_earnings = @vendor.total_earnings
      @available_for_payout = @vendor.available_for_payout
      @pending_earnings = @vendor.pending_earnings
      @paid_out_total = @vendor.paid_out_total
      @ready_orders = @vendor.ready_orders_for_payout.limit(10)
      @recent_payouts = @vendor.vendor_payouts.recent.limit(5)
    end

    def new_payout
      @ready_orders = @vendor.ready_orders_for_payout

      if @ready_orders.empty?
        redirect_to admin_vendor_earnings_path, alert: "No orders available for payout. Orders must be delivered and paid."
        return
      end

      if @vendor.has_pending_payout_request?
        redirect_to admin_vendor_earnings_path, alert: "You already have a pending payout request. Please wait for it to be processed."
        return
      end

      @selected_orders = params[:order_ids] ? @ready_orders.where(id: params[:order_ids]) : []

      if @selected_orders.any?
        @total_amount = @selected_orders.sum(:vendor_earnings)
        @platform_fee = @selected_orders.sum(:platform_fee_amount)
        @gateway_fee = @selected_orders.sum(:gateway_fee_amount)
        @gateway_gst = @selected_orders.sum(:gateway_gst_amount)
        @total_fees = @platform_fee + @gateway_fee + @gateway_gst
        # vendor_earnings is already after fees, so net_payout = total_amount
        @net_payout = @total_amount
      end
    end

    def create_payout
      order_ids = params[:order_ids] || []

      if order_ids.empty?
        redirect_to new_payout_admin_vendor_earnings_path, alert: "Please select at least one order."
        return
      end

      @selected_orders = @vendor.ready_orders_for_payout.where(id: order_ids)

      if @selected_orders.count != order_ids.count
        redirect_to new_payout_admin_vendor_earnings_path, alert: "Invalid order selection."
        return
      end

      @total_amount = @selected_orders.sum(:vendor_earnings)

      # Validate minimum payout
      if @total_amount < @config.minimum_payout_amount
        redirect_to new_payout_admin_vendor_earnings_path, alert: "Minimum payout amount is ₹#{@config.minimum_payout_amount}. You selected ₹#{@total_amount}."
        return
      end

      # Validate maximum payout
      if @total_amount > @config.maximum_payout_amount
        redirect_to new_payout_admin_vendor_earnings_path, alert: "Maximum payout amount is ₹#{@config.maximum_payout_amount}. You selected ₹#{@total_amount}."
        return
      end

      ActiveRecord::Base.transaction do
        @payout = @vendor.vendor_payouts.create!(
          total_amount: @total_amount,
          platform_fee_total: @selected_orders.sum(:platform_fee_amount),
          gateway_fee_total: @selected_orders.sum(:gateway_fee_amount),
          gateway_gst_total: @selected_orders.sum(:gateway_gst_amount),
          # vendor_earnings is already net of fees, so net_payout = total_amount
          net_payout: @total_amount,
          status: "pending"
        )

        # Link orders to payout
        @selected_orders.each do |order|
          VendorPayoutOrder.create!(vendor_payout: @payout, order: order)
          order.update!(payout_status: "requested")
        end
      end

      redirect_to admin_vendor_earnings_path, notice: "Payout request for ₹#{@payout.net_payout} submitted successfully. Admin will review and process it."
    rescue => e
      redirect_to new_payout_admin_vendor_earnings_path, alert: "Error creating payout: #{e.message}"
    end

    def payouts
      @payouts = @vendor.vendor_payouts.recent
    end

    def show_payout
      @payout = @vendor.vendor_payouts.find(params[:id])
      @orders = @payout.orders.order(delivered_at: :desc)
    end

    private

    def require_vendor_context
      unless current_vendor_user?
        redirect_to admin_root_path, alert: "Only vendors can access earnings."
      end
    end

    def set_vendor
      @vendor = current_vendor
    end

    def set_config
      @config = PlatformFeeConfig.current
    end
  end
end
