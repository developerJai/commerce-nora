module Admin
  class PayoutsController < BaseController
    before_action :require_admin_role!
    before_action :set_config
    before_action :set_payout, only: [ :show, :approve, :reject, :mark_paid ]

    def index
      @status = params[:status] || "pending"
      payouts = VendorPayout.includes(:vendor).order(created_at: :desc)

      case @status
      when "pending"
        payouts = payouts.pending
      when "approved"
        payouts = payouts.approved
      when "paid"
        payouts = payouts.paid
      when "rejected"
        payouts = payouts.rejected
      end

      @pagy, @payouts = pagy(payouts, limit: 20)

      # Stats
      @pending_count = VendorPayout.pending.count
      @approved_count = VendorPayout.approved.count
      @total_pending_amount = VendorPayout.pending.sum(:net_payout)
    end

    def show
      @orders = @payout.orders.includes(:order_items).order(delivered_at: :desc)
    end

    def approve
      if @payout.approve!(params[:notes])
        redirect_to admin_payout_path(@payout), notice: "Payout approved successfully. Vendor can now be paid."
      else
        redirect_to admin_payout_path(@payout), alert: "Could not approve payout."
      end
    end

    def reject
      if @payout.reject!(params[:notes])
        redirect_to admin_payouts_path, notice: "Payout rejected. Orders returned to vendor's available balance."
      else
        redirect_to admin_payout_path(@payout), alert: "Could not reject payout."
      end
    end

    def mark_paid
      transaction_ref = params[:transaction_reference]&.strip

      if transaction_ref.blank?
        redirect_to admin_payout_path(@payout), alert: "Transaction reference is required."
        return
      end

      if @payout.mark_as_paid!(transaction_ref, params[:notes])
        redirect_to admin_payout_path(@payout), notice: "Payout marked as paid with reference: #{transaction_ref}"
      else
        redirect_to admin_payout_path(@payout), alert: "Could not mark payout as paid."
      end
    end

    private

    def set_config
      @config = PlatformFeeConfig.current
    end

    def set_payout
      @payout = VendorPayout.find(params[:id])
    end
  end
end
