module Admin
  class VendorsController < BaseController
    before_action :require_admin_role!
    before_action :set_vendor, only: [:show, :edit, :update, :destroy, :toggle_status, :act_as, :reset_password]

    def index
      @q = params[:q]
      vendors = Vendor.all
      vendors = vendors.where("business_name ILIKE :q OR contact_name ILIKE :q OR email ILIKE :q", q: "%#{@q}%") if @q.present?
      vendors = vendors.ordered
      @pagy, @vendors = pagy(vendors, limit: 20)
    end

    def show
      @products_count = @vendor.products.count
      @active_products_count = @vendor.products.where(active: true).count
      @orders_count = @vendor.orders.placed.count
      @total_revenue = @vendor.orders.placed.sum(:total_amount)
      @total_earnings = @vendor.total_earnings
      @admin_user = @vendor.admin_users.first

      # Order stats by status
      placed_orders = @vendor.orders.placed
      @order_stats = {
        confirmed: placed_orders.where(status: "confirmed").count,
        processing: placed_orders.where(status: "processing").count,
        shipped: placed_orders.where(status: "shipped").count,
        delivered: placed_orders.where(status: "delivered").count,
        cancelled: placed_orders.where(status: "cancelled").count
      }

      # Recent orders
      @recent_orders = @vendor.orders.placed.includes(:customer).recent.limit(10)

      # Top products by order count
      @top_products = @vendor.products
        .joins(:variants => :order_items)
        .joins("INNER JOIN orders ON orders.id = order_items.order_id AND orders.is_draft = false AND orders.placed_at IS NOT NULL")
        .select("products.*, COUNT(DISTINCT orders.id) as orders_count, SUM(order_items.total_price) as items_revenue")
        .group("products.id")
        .order("orders_count DESC")
        .limit(5)
    end

    def new
      @vendor = Vendor.new
    end

    def create
      @vendor = Vendor.new(vendor_params)

      ActiveRecord::Base.transaction do
        if @vendor.save
          # Create an AdminUser with vendor role for login
          admin_user = AdminUser.new(
            name: @vendor.contact_name,
            email: @vendor.email,
            password: params[:vendor][:password],
            password_confirmation: params[:vendor][:password_confirmation],
            role: 'vendor',
            vendor: @vendor
          )

          if admin_user.save
            redirect_to admin_vendor_path(@vendor), notice: "Vendor onboarded successfully"
          else
            @vendor.errors.merge!(admin_user.errors)
            raise ActiveRecord::Rollback
          end
        end
      end

      render :new, status: :unprocessable_entity if @vendor.errors.any? || @vendor.new_record?
    end

    def edit
    end

    def update
      if @vendor.update(vendor_params)
        redirect_to admin_vendor_path(@vendor), notice: "Vendor updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @vendor.destroy
      redirect_to admin_vendors_path, notice: "Vendor deleted successfully"
    end

    def toggle_status
      @vendor.update(active: !@vendor.active?)

      respond_to do |format|
        format.html { redirect_to admin_vendors_path, notice: "Vendor #{@vendor.active? ? 'enabled' : 'disabled'}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@vendor) }
      end
    end

    def reset_password
      admin_user = @vendor.admin_users.first

      unless admin_user
        redirect_to admin_vendor_path(@vendor), alert: "No login account found for this vendor"
        return
      end

      new_password = params[:vendor][:password]
      password_confirmation = params[:vendor][:password_confirmation]

      if new_password.blank?
        redirect_to admin_vendor_path(@vendor), alert: "Password cannot be blank"
        return
      end

      if new_password != password_confirmation
        redirect_to admin_vendor_path(@vendor), alert: "Password and confirmation do not match"
        return
      end

      if admin_user.update(password: new_password, password_confirmation: password_confirmation)
        flash[:reset_password] = new_password
        redirect_to admin_vendor_path(@vendor), notice: "Password reset successfully. Copy the password below and share it with the vendor."
      else
        redirect_to admin_vendor_path(@vendor), alert: admin_user.errors.full_messages.to_sentence
      end
    end

    def act_as
      session[:acting_as_vendor_id] = @vendor.id
      redirect_to admin_root_path, notice: "Now acting as #{@vendor.business_name}"
    end

    def exit_vendor_mode
      session.delete(:acting_as_vendor_id)
      redirect_to admin_vendors_path, notice: "Exited vendor mode"
    end

    private

    def set_vendor
      @vendor = Vendor.find(params[:id])
    end

    def vendor_params
      params.require(:vendor).permit(
        :business_name, :contact_name, :email, :phone,
        :gst_number, :address_line1, :address_line2,
        :city, :state, :pincode, :active
      )
    end
  end
end
