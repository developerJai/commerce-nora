module Admin
  class CouponsController < BaseController
    before_action :require_admin_role!
    before_action :set_coupon, only: [:show, :edit, :update, :destroy, :toggle_status]

    def index
      @pagy, @coupons = pagy(Coupon.order(created_at: :desc), limit: 20)
    end

    def show
      @orders_with_coupon = @coupon.orders.placed.recent.limit(10)
    end

    def new
      @coupon = Coupon.new
    end

    def create
      @coupon = Coupon.new(coupon_params)

      if @coupon.save
        redirect_to admin_coupons_path, notice: "Coupon created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @coupon.update(coupon_params)
        redirect_to admin_coupons_path, notice: "Coupon updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @coupon.destroy
      redirect_to admin_coupons_path, notice: "Coupon deleted successfully"
    end

    def toggle_status
      @coupon.update(active: !@coupon.active?)
      
      respond_to do |format|
        format.html { redirect_to admin_coupons_path, notice: "Coupon #{@coupon.active? ? 'enabled' : 'disabled'}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@coupon) }
      end
    end

    private

    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

    def coupon_params
      params.require(:coupon).permit(
        :code, :name, :description, :discount_type, :discount_value,
        :minimum_order_amount, :maximum_discount, :usage_limit,
        :starts_at, :expires_at, :active
      )
    end
  end
end
