class Api::MobileController < ApplicationController
  skip_forgery_protection

  def navigation
    render json: {
      tabs: [
        { name: "Home", path: root_url },
        { name: "Search", path: products_url },
        { name: "Cart", path: cart_url },
        { name: "Orders", path: orders_url },
        { name: "Account", path: customer_logged_in? ? account_url : login_url }
      ],
      hide_native_menu_patterns: [
        { path: "/products/*", description: "Product detail pages" },
        { path: "/checkout", description: "Checkout pages" }
      ]
    }
  end

  def cart_count
    render json: { count: current_cart.item_count }
  end

  def check_update
    platform = params[:platform].to_s.downcase
    current_version = params[:current_version].to_s

    result = AppVersion.check_update(platform, current_version)
    render json: result
  end
end
