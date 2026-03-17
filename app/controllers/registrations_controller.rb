class RegistrationsController < ApplicationController
  before_action :redirect_if_logged_in

  def new
    @customer = Customer.new
  end

  def create
    # Split full name if only first_name is provided
    if params[:customer][:first_name].present? && params[:customer][:last_name].blank?
      full_name = params[:customer][:first_name].strip
      names = full_name.split(" ")
      params[:customer][:first_name] = names.first
      params[:customer][:last_name] = names[1..].join(" ") # all after first word
    end

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
