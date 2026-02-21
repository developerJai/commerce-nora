class CartsController < ApplicationController
  before_action :set_variant, only: [ :add ]
  before_action :set_cart_item, only: [ :update_item, :remove ]

  def show
    @cart = current_cart
    @cart_items = @cart.cart_items.includes(product_variant: [ :product, image_attachment: :blob ])
  end

  def coupons
    @cart = current_cart
    @subtotal = @cart.subtotal
    @coupons = Coupon.available.order(created_at: :desc)
    @applicable_coupons = @coupons.select { |c| c.applicable_to?(@subtotal) }
    @inapplicable_coupons = @coupons - @applicable_coupons

    if params[:close].to_s == "1"
      render inline: "<turbo-frame id=\"coupon_modal\"></turbo-frame>", layout: false
    else
      render :coupons
    end
  end

  def add
    @cart_item = current_cart.add_item(@variant, params[:quantity]&.to_i || 1)
    @from_product_page = params[:from_product_page].to_s == "1"
    @show_toast = params[:show_toast].to_s == "1"

    # Clear memoized cart so item_count returns fresh data
    @current_cart = nil

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Added to cart" }
      format.turbo_stream
    end
  end

  def update_item
    quantity = params[:quantity].to_i
    @variant = @cart_item.product_variant

    if quantity <= 0
      @cart_item.destroy
      @cart_item = nil
    else
      current_cart.update_item(@variant, quantity)
      @cart_item = current_cart.cart_items.find_by(product_variant: @variant)
    end

    # Clear memoized cart so item_count/subtotal return fresh data
    @current_cart = nil

    respond_to do |format|
      format.html { redirect_to cart_path }
      format.turbo_stream do
        @cart = current_cart
        @cart_items = @cart.cart_items.includes(product_variant: [ :product, image_attachment: :blob ])
      end
    end
  end

  def remove
    @variant = @cart_item.product_variant
    @cart_item.destroy

    # Clear memoized cart so item_count/subtotal return fresh data
    @current_cart = nil

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Item removed from cart" }
      format.turbo_stream do
        @cart = current_cart
        @cart_items = @cart.cart_items.includes(product_variant: [ :product, image_attachment: :blob ])

        streams = [
          turbo_stream.replace("cart-controls-#{@variant.id}",
            partial: "shared/cart_controls",
            locals: { variant: @variant, cart_item: nil }),
          turbo_stream.update("product-cart-controls-#{@variant.id}",
            partial: "products/cart_controls",
            locals: { variant: @variant, cart_item: nil }),
          turbo_stream.update("cart-count", partial: "shared/cart_count_badge"),
          turbo_stream.update("cart-item-count", current_cart.item_count.to_s),
          turbo_stream.update("cart-items",
            partial: "carts/items",
            locals: { cart_items: @cart_items }),
          turbo_stream.update("cart-summary",
            partial: "carts/summary",
            locals: { cart: @cart })
        ]

        render turbo_stream: streams
      end
    end
  end

  def clear
    current_cart.clear!
    redirect_to cart_path, notice: "Cart cleared"
  end

  def apply_coupon
    code = params[:coupon_code]&.strip
    coupon = Coupon.find_by_code(code)

    if coupon.nil?
      redirect_to cart_path, alert: "Invalid coupon code"
    elsif !coupon.valid_for_use?
      redirect_to cart_path, alert: "This coupon is not valid"
    elsif !coupon.applicable_to?(current_cart.subtotal)
      redirect_to cart_path, alert: "Minimum order amount of #{helpers.format_price(coupon.minimum_order_amount)} required"
    else
      session[:coupon_id] = coupon.id
      redirect_to cart_path, notice: "Coupon applied! #{coupon.display_value} off"
    end
  end

  def remove_coupon
    session.delete(:coupon_id)
    redirect_to cart_path, notice: "Coupon removed"
  end

  # POST /cart/add_bundle/:bundle_deal_id
  def add_bundle
    @bundle_deal = BundleDeal.active.find(params[:bundle_deal_id])

    # Add each product in the bundle to cart
    @bundle_deal.bundle_deal_items.includes(:product).each do |item|
      variant = item.product.default_variant
      if variant
        current_cart.add_item(variant, item.quantity)
      end
    end

    # Apply bundle discount as a session variable
    session[:bundle_deal_id] = @bundle_deal.id
    session[:bundle_discount] = @bundle_deal.savings_amount.to_f

    @current_cart = nil

    redirect_to cart_path, notice: "#{@bundle_deal.title} bundle added to cart! You saved #{@bundle_deal.savings_display}"
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Bundle deal not found"
  end

  private

  def set_variant
    @variant = ProductVariant.active.find(params[:variant_id])
  end

  def set_cart_item
    @cart_item = current_cart.cart_items.find_by!(product_variant_id: params[:variant_id])
  end
end
