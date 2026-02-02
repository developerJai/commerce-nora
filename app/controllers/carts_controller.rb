class CartsController < ApplicationController
  before_action :set_variant, only: [:add]
  before_action :set_cart_item, only: [:update_item, :remove]

  def show
    @cart = current_cart
    @cart_items = @cart.cart_items.includes(product_variant: [:product, image_attachment: :blob])
  end

  def add
    @cart_item = current_cart.add_item(@variant, params[:quantity]&.to_i || 1)
    
    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Added to cart" }
      format.turbo_stream do
        streams = [
          turbo_stream.update("cart-count", current_cart.item_count.to_s),
          turbo_stream.update("cart-controls-#{@variant.id}", 
            partial: "shared/cart_controls", 
            locals: { variant: @variant, cart_item: @cart_item })
        ]
        render turbo_stream: streams
      end
    end
  end

  def update_item
    quantity = params[:quantity].to_i
    @variant = @cart_item.product_variant
    
    if quantity <= 0
      # Remove item when quantity is 0 or less
      @cart_item.destroy
      @cart_item = nil
    else
      current_cart.update_item(@variant, quantity)
      @cart_item = current_cart.cart_items.find_by(product_variant: @variant)
    end
    
    respond_to do |format|
      format.html { redirect_to cart_path }
      format.turbo_stream do
        @cart = current_cart
        @cart_items = @cart.cart_items.includes(product_variant: [:product, image_attachment: :blob])
        
        streams = [
          turbo_stream.update("cart-count", current_cart.item_count.to_s),
          turbo_stream.update("cart-item-count", current_cart.item_count.to_s),
          turbo_stream.update("cart-controls-#{@variant.id}", 
            partial: "shared/cart_controls", 
            locals: { variant: @variant, cart_item: @cart_item }),
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

  def remove
    @variant = @cart_item.product_variant
    @cart_item.destroy
    
    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Item removed from cart" }
      format.turbo_stream do
        @cart = current_cart
        @cart_items = @cart.cart_items.includes(product_variant: [:product, image_attachment: :blob])
        
        streams = [
          turbo_stream.update("cart-count", current_cart.item_count.to_s),
          turbo_stream.update("cart-item-count", current_cart.item_count.to_s),
          turbo_stream.update("cart-controls-#{@variant.id}", 
            partial: "shared/cart_controls", 
            locals: { variant: @variant, cart_item: nil }),
          turbo_stream.update("cart-items", 
            partial: "carts/items", 
            locals: { cart_items: @cart_items }),
          turbo_stream.update("cart-summary", 
            partial: "carts/summary", 
            locals: { cart: @cart }),
          turbo_stream.prepend("flash", partial: "shared/flash", locals: { notice: "Item removed" })
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
      redirect_to cart_path, alert: "Minimum order amount of #{format_price(coupon.minimum_order_amount)} required"
    else
      session[:coupon_id] = coupon.id
      redirect_to cart_path, notice: "Coupon applied! #{coupon.display_value} off"
    end
  end

  def remove_coupon
    session.delete(:coupon_id)
    redirect_to cart_path, notice: "Coupon removed"
  end

  private

  def set_variant
    @variant = ProductVariant.active.find(params[:variant_id])
  end

  def set_cart_item
    @cart_item = current_cart.cart_items.find(params[:item_id])
  end
end
