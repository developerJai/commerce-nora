class SessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new
    # Store the return URL if provided
    session[:return_to] = params[:return_to] || request.referer
  end

  def create
    customer = Customer.authenticate(params[:email], params[:password])

    if customer
      session[:customer_id] = customer.id
      customer.update(last_login_at: Time.current)

      # Merge guest cart
      if session[:cart_token]
        guest_cart = Cart.find_by(token: session[:cart_token])
        if guest_cart
          customer.active_cart.merge_with!(guest_cart)
          session.delete(:cart_token)
        end
      end

      # Redirect to stored location or account page
      redirect_to session.delete(:return_to) || account_path
    else
      flash.now[:alert] = "Invalid email or password"
      @email = params[:email] # Preserve email for re-display
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:customer_id)

    if request.user_agent&.include?("Hotwire")
      # For native mobile apps: send bridge messages to reset native state,
      # then navigate via JS to avoid Turbo hanging the screen
      render html: native_logout_bridge_html.html_safe, layout: false
    else
      redirect_to root_path, notice: "You have been logged out"
    end
  end

  private

  def redirect_if_logged_in
    redirect_to root_path if customer_logged_in?
  end

  def native_logout_bridge_html
    root = root_url
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"></head>
      <body style="background:#fafaf9;">
        <script>
          // Notify iOS native app
          if (window.webkit && window.webkit.messageHandlers) {
            if (window.webkit.messageHandlers.cartCount) {
              window.webkit.messageHandlers.cartCount.postMessage(0);
            }
            if (window.webkit.messageHandlers.userLoggedOut) {
              window.webkit.messageHandlers.userLoggedOut.postMessage(true);
            }
          }
          // Notify Android native app
          if (window.NoralooksAndroid) {
            if (window.NoralooksAndroid.updateCartCount) {
              window.NoralooksAndroid.updateCartCount(0);
            }
            if (window.NoralooksAndroid.onUserLoggedOut) {
              window.NoralooksAndroid.onUserLoggedOut();
            }
          }
          // Navigate to home after a brief delay for bridge messages to process
          setTimeout(function() {
            window.location.replace("#{root}");
          }, 150);
        </script>
      </body>
      </html>
    HTML
  end
end
