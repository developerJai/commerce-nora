module Admin
  class VendorsController < BaseController
    before_action :require_admin_role!
    before_action :set_vendor, only: [:show, :edit, :update, :destroy, :toggle_status, :act_as]

    def index
      @q = params[:q]
      vendors = Vendor.all
      vendors = vendors.where("business_name ILIKE :q OR contact_name ILIKE :q OR email ILIKE :q", q: "%#{@q}%") if @q.present?
      vendors = vendors.ordered
      @pagy, @vendors = pagy(vendors, limit: 20)
    end

    def show
      @products_count = @vendor.products.count
      @orders_count = @vendor.orders.placed.count
      @total_revenue = @vendor.orders.placed.sum(:total_amount)
      @admin_user = @vendor.admin_users.first
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
