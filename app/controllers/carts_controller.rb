class CartsController < ApplicationController
  before_action :set_variant, only: [ :add ]
  before_action :set_cart_item, only: [ :update_item, :remove ]

  def show
    @cart = current_cart
    @cart_items = @cart.cart_items.includes(product_variant: [ { product: :vendor }, image_attachment: :blob ])

    # Check if cart has multiple vendors
    @vendor_ids = @cart_items.map { |item| item.product_variant.product.vendor_id }.uniq
    @multi_vendor = @vendor_ids.size > 1

    # Group items by vendor if multi-vendor
    if @multi_vendor
      @items_by_vendor = @cart_items.group_by { |item| item.product_variant.product.vendor }
    end

    # Check if coupons are enabled in settings
    store = StoreSetting.instance
    @coupons_enabled = store.coupons_enabled?
    # Allow coupons for multi-vendor carts if the setting is enabled
    @coupon_blocked_by_multi_vendor = @multi_vendor && !store.multi_vendor_coupons_enabled?
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
        @cart = current_cart.reload
        @cart_items = @cart.cart_items.reload.includes(product_variant: [ { product: :vendor }, image_attachment: :blob ])

        # Check if cart has multiple vendors (same logic as show action)
        vendor_ids = @cart_items.map { |item| item.product_variant.product.vendor_id }.uniq
        @multi_vendor = vendor_ids.size > 1
        store = StoreSetting.instance
        @coupons_enabled = store.coupons_enabled?
        coupon_blocked = @multi_vendor && !store.multi_vendor_coupons_enabled?

        # Group items by vendor if multi-vendor
        if @multi_vendor
          @items_by_vendor = @cart_items.group_by { |item| item.product_variant.product.vendor }
        end

        streams = []

        # Update cart content based on whether cart is empty or not
        if current_cart.empty?
          streams << turbo_stream.replace("cart-content",
            partial: "carts/empty_cart")
          streams << turbo_stream.update("cart-header",
            partial: "carts/header",
            locals: { cart: @cart })
        else
          streams << turbo_stream.update("cart-items",
            partial: @multi_vendor ? "carts/items_by_vendor" : "carts/items",
            locals: @multi_vendor ? { items_by_vendor: @items_by_vendor } : { cart_items: @cart_items })
          streams << turbo_stream.update("cart-summary",
            partial: "carts/summary",
            locals: { cart: @cart })
          streams << turbo_stream.update("cart-summary-mobile",
            partial: "carts/summary_mobile",
            locals: { cart: @cart })
          streams << turbo_stream.update("cart-coupon-section",
            partial: "carts/coupon_section",
            locals: { coupons_enabled: @coupons_enabled, multi_vendor: coupon_blocked })
          streams << turbo_stream.update("cart-coupon-section-mobile",
            partial: "carts/coupon_section_mobile",
            locals: { coupons_enabled: @coupons_enabled, multi_vendor: coupon_blocked, cart: @cart })
          streams << turbo_stream.update("cart-checkout-bar",
            partial: "carts/checkout_bar_mobile",
            locals: { cart: @cart })
        end

        # Update cart count badges
        streams << turbo_stream.update("cart-count", partial: "shared/cart_count_badge")
        streams << turbo_stream.update("mobile-cart-count", partial: "shared/mobile_cart_count_badge")
        streams << turbo_stream.update("cart-item-count", current_cart.item_count.to_s)

        # Update product controls if we have a variant
        if @variant
          streams << turbo_stream.replace("cart-controls-#{@variant.id}",
            partial: "shared/cart_controls",
            locals: { variant: @variant, cart_item: @cart_item })
          streams << turbo_stream.update("product-cart-controls-#{@variant.id}",
            partial: "products/cart_controls",
            locals: { variant: @variant, cart_item: @cart_item })
        end

        # Notify native app of cart count change
        streams << native_cart_count_stream

        render turbo_stream: streams
      end
    end
  end

  def remove
    @variant = @cart_item.product_variant
    @cart_item.destroy!

    # Clear memoized cart so item_count/subtotal return fresh data
    @current_cart = nil

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Item removed from cart" }
      format.turbo_stream do
        @cart = current_cart.reload
        @cart_items = @cart.cart_items.reload.includes(product_variant: [ { product: :vendor }, image_attachment: :blob ])

        # Check if cart has multiple vendors (same logic as show action)
        vendor_ids = @cart_items.map { |item| item.product_variant.product.vendor_id }.uniq
        @multi_vendor = vendor_ids.size > 1
        store = StoreSetting.instance
        @coupons_enabled = store.coupons_enabled?
        coupon_blocked = @multi_vendor && !store.multi_vendor_coupons_enabled?

        # Group items by vendor if multi-vendor
        if @multi_vendor
          @items_by_vendor = @cart_items.group_by { |item| item.product_variant.product.vendor }
        end

        streams = [
          turbo_stream.replace("cart-controls-#{@variant.id}",
            partial: "shared/cart_controls",
            locals: { variant: @variant, cart_item: nil }),
          turbo_stream.update("product-cart-controls-#{@variant.id}",
            partial: "products/cart_controls",
            locals: { variant: @variant, cart_item: nil }),
          turbo_stream.update("cart-count", partial: "shared/cart_count_badge"),
          turbo_stream.update("mobile-cart-count", partial: "shared/mobile_cart_count_badge"),
          turbo_stream.update("cart-item-count", @cart.item_count.to_s)
        ]

        # Update cart content based on whether cart is empty or not
        if @cart.empty?
          streams << turbo_stream.replace("cart-content",
            partial: "carts/empty_cart")
          streams << turbo_stream.update("cart-header",
            partial: "carts/header",
            locals: { cart: @cart })
        else
          streams << turbo_stream.update("cart-items",
            partial: @multi_vendor ? "carts/items_by_vendor" : "carts/items",
            locals: @multi_vendor ? { items_by_vendor: @items_by_vendor } : { cart_items: @cart_items })
          streams << turbo_stream.update("cart-summary",
            partial: "carts/summary",
            locals: { cart: @cart })
          streams << turbo_stream.update("cart-summary-mobile",
            partial: "carts/summary_mobile",
            locals: { cart: @cart })
          streams << turbo_stream.update("cart-coupon-section",
            partial: "carts/coupon_section",
            locals: { coupons_enabled: @coupons_enabled, multi_vendor: coupon_blocked })
          streams << turbo_stream.update("cart-coupon-section-mobile",
            partial: "carts/coupon_section_mobile",
            locals: { coupons_enabled: @coupons_enabled, multi_vendor: coupon_blocked, cart: @cart })
          streams << turbo_stream.update("cart-checkout-bar",
            partial: "carts/checkout_bar_mobile",
            locals: { cart: @cart })
        end

        # Notify native app of cart count change
        streams << native_cart_count_stream

        render turbo_stream: streams
      end
    end
  end

  def clear
    current_cart.clear!
    redirect_to cart_path, notice: "Cart cleared"
  end

  def apply_coupon
    store = StoreSetting.instance

    # Block coupon application if coupons are disabled or multi-vendor without the setting
    unless store.coupons_enabled?
      return respond_to_coupon_action(alert: "Coupons are not available")
    end

    cart_items = current_cart.cart_items.includes(product_variant: { product: :vendor })
    multi_vendor = cart_items.map { |i| i.product_variant.product.vendor_id }.uniq.size > 1
    if multi_vendor && !store.multi_vendor_coupons_enabled?
      return respond_to_coupon_action(alert: "Coupons are not available for multi-vendor orders")
    end

    code = params[:coupon_code]&.strip
    coupon = Coupon.find_by_code(code)

    if coupon.nil?
      respond_to_coupon_action(alert: "Invalid coupon code")
    elsif !coupon.valid_for_use?
      respond_to_coupon_action(alert: "This coupon is not valid")
    elsif !coupon.applicable_to?(current_cart.subtotal)
      respond_to_coupon_action(alert: "Minimum order amount of #{helpers.format_price(coupon.minimum_order_amount)} required")
    else
      session[:coupon_id] = coupon.id
      respond_to_coupon_action
    end
  end

  def remove_coupon
    session.delete(:coupon_id)
    respond_to_coupon_action
  end

  private

  def set_variant
    @variant = ProductVariant.active.find(params[:variant_id])
  end

  def set_cart_item
    @cart_item = current_cart.cart_items.find_by!(product_variant_id: params[:variant_id])
  end

  def respond_to_coupon_action(alert: nil)
    respond_to do |format|
      format.html { redirect_to cart_path, alert: alert }
      format.turbo_stream do
        @cart = current_cart
        store = StoreSetting.instance
        coupons_enabled = store.coupons_enabled?
        cart_items = @cart.cart_items.includes(product_variant: { product: :vendor })
        vendor_ids = cart_items.map { |i| i.product_variant.product.vendor_id }.uniq
        multi_vendor = vendor_ids.size > 1
        coupon_blocked = multi_vendor && !store.multi_vendor_coupons_enabled?

        streams = [
          turbo_stream.update("cart-coupon-section",
            partial: "carts/coupon_section",
            locals: { coupons_enabled: coupons_enabled, multi_vendor: coupon_blocked }),
          turbo_stream.update("cart-coupon-section-mobile",
            partial: "carts/coupon_section_mobile",
            locals: { coupons_enabled: coupons_enabled, multi_vendor: coupon_blocked, cart: @cart }),
          turbo_stream.update("cart-summary",
            partial: "carts/summary",
            locals: { cart: @cart }),
          turbo_stream.update("cart-summary-mobile",
            partial: "carts/summary_mobile",
            locals: { cart: @cart }),
          turbo_stream.update("cart-checkout-bar",
            partial: "carts/checkout_bar_mobile",
            locals: { cart: @cart })
        ]

        # Close the coupon modal on success, show toast on error
        if alert.present?
          streams << turbo_stream.append("toasts",
            partial: "shared/toast",
            locals: { message: alert, variant: :error })
        else
          # Close the modal by replacing the frame with empty content
          streams << turbo_stream.update("coupon_modal", "")
        end

        render turbo_stream: streams
      end
    end
  end

  def native_cart_count_stream
    count = current_cart.item_count
    turbo_stream.append("native-bridge") do
      helpers.content_tag(:script, <<~JS.html_safe)
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.cartCount) {
          window.webkit.messageHandlers.cartCount.postMessage(#{count});
        }
        if (window.NoralooksAndroid && window.NoralooksAndroid.updateCartCount) {
          window.NoralooksAndroid.updateCartCount(#{count});
        }
      JS
    end
  end
end
