class RegistrationsController < ApplicationController
  before_action :redirect_if_logged_in

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      session[:customer_id] = @customer.id
      
      # Merge guest cart
      if session[:cart_token]
        guest_cart = Cart.find_by(token: session[:cart_token])
        if guest_cart
          @customer.active_cart.merge_with!(guest_cart)
          session.delete(:cart_token)
        end
      end

      redirect_to root_path, notice: "Welcome to Auracraft!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def customer_params
    params.require(:customer).permit(:first_name, :last_name, :email, :phone, :password, :password_confirmation)
  end

  def redirect_if_logged_in
    redirect_to root_path if customer_logged_in?
  end
end
