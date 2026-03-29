class SessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new
    # Store the return URL if provided (skip external/unreliable referrers)
    session[:return_to] = params[:return_to] if params[:return_to].present?
  end

  def create
    customer = Customer.authenticate(params[:email], params[:password])

    if customer
      session[:customer_id] = customer.id
      customer.update_column(:last_login_at, Time.current)

      # Merge guest cart
      if session[:cart_token]
        guest_cart = Cart.find_by(token: session[:cart_token])
        if guest_cart
          customer.active_cart.merge_with!(guest_cart)
          session.delete(:cart_token)
        end
      end

      redirect_to session.delete(:return_to) || account_path
    else
      flash.now[:alert] = "Invalid email or password"
      @email = params[:email] # Preserve email for re-display
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:customer_id)
    session.delete(:coupon_id)
    redirect_to login_path, notice: "You have been logged out"
  end

  private

  def redirect_if_logged_in
    redirect_to root_path if customer_logged_in?
  end
end
