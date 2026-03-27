class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_customer, :customer_logged_in?, :current_cart, :search_placeholder

  private

  def current_customer
    @current_customer ||= Customer.find_by(id: session[:customer_id]) if session[:customer_id]
  end

  def customer_logged_in?
    current_customer.present?
  end

  def require_customer
    unless customer_logged_in?
      # Store the full URL to redirect back after login
      session[:return_to] = request.fullpath
      redirect_to signin_path
    end
  end

  def current_cart
    @current_cart ||= find_or_create_cart
  end

  def find_or_create_cart
    if customer_logged_in?
      cart = current_customer.active_cart
      # Merge guest cart if exists
      if session[:cart_token]
        guest_cart = Cart.find_by(token: session[:cart_token])
        if guest_cart && guest_cart != cart
          cart.merge_with!(guest_cart)
          session.delete(:cart_token)
        end
      end
      cart
    else
      if session[:cart_token]
        Cart.find_by(token: session[:cart_token]) || create_guest_cart
      else
        create_guest_cart
      end
    end
  end

  def create_guest_cart
    cart = Cart.create!(token: SecureRandom.uuid)
    session[:cart_token] = cart.token
    cart
  end

  def search_placeholder
    active_categories = Category.active.root.ordered.pluck(:name)
    search_parts = []

    # Add "jewellery" if any jewellery categories are active
    jewellery_categories = [ "Necklaces", "Rings", "Earrings", "Bangles", "Bracelets", "Pendants" ]
    if (active_categories & jewellery_categories).any?
      search_parts << "jewellery"
    end

    # Add "traditional wear" if active
    if active_categories.include?("Traditional Wear")
      search_parts << "traditional wear"
    end

    # Add "gifts" if active
    if active_categories.include?("Gifts")
      search_parts << "gifts"
    end

    if search_parts.length > 1
      "Search #{search_parts[0..-2].join(', ')} & #{search_parts.last}..."
    else
      "Search #{search_parts.first}..."
    end
  end
end
