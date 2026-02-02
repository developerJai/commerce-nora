module Admin
  class CustomersController < BaseController
    include Pagy::Backend

    before_action :set_customer, only: [:show, :edit, :update, :destroy, :toggle_status]

    def index
      @q = params[:q]
      customers = Customer.all
      customers = customers.where("email ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q", q: "%#{@q}%") if @q.present?
      customers = customers.order(created_at: :desc)
      @pagy, @customers = pagy(customers, items: 20)
    end

    def show
      @orders = @customer.orders.placed.recent.limit(10)
      @addresses = @customer.addresses
    end

    def edit
    end

    def update
      if @customer.update(customer_params)
        redirect_to admin_customer_path(@customer), notice: "Customer updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @customer.destroy
      redirect_to admin_customers_path, notice: "Customer deleted successfully"
    end

    def toggle_status
      @customer.update(active: !@customer.active?)
      
      respond_to do |format|
        format.html { redirect_back fallback_location: admin_customers_path, notice: "Customer #{@customer.active? ? 'enabled' : 'disabled'}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@customer) }
      end
    end

    private

    def set_customer
      @customer = Customer.find(params[:id])
    end

    def customer_params
      params.require(:customer).permit(:first_name, :last_name, :email, :phone, :active)
    end
  end
end
