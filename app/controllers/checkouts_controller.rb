class CheckoutsController < ApplicationController
  before_action :require_customer
  before_action :require_cart_items

  def show
    @addresses = current_customer.addresses.default_first
    @selected_address = current_customer.default_shipping_address
  end

  def address
    @addresses = current_customer.addresses.default_first
    @address = Address.new
  end

  def save_address
    if params[:address_id].present?
      @address = current_customer.addresses.find(params[:address_id])
      session[:checkout_address_id] = @address.id
      redirect_to confirm_checkout_path
    else
      @address = current_customer.addresses.build(address_params)
      if @address.save
        session[:checkout_address_id] = @address.id
        redirect_to confirm_checkout_path
      else
        @addresses = current_customer.addresses.default_first
        render :address, status: :unprocessable_entity
      end
    end
  end

  def confirm
    @address = current_customer.addresses.find_by(id: session[:checkout_address_id]) ||
               current_customer.default_shipping_address

    unless @address
      redirect_to address_checkout_path, alert: "Please select a shipping address"
      return
    end

    @coupon = Coupon.find_by(id: session[:coupon_id]) if session[:coupon_id]
    @cart = current_cart
    @subtotal = @cart.subtotal
    @discount = @coupon&.calculate_discount(@subtotal) || 0
    @shipping = 0 # Free shipping for now
    @total = @subtotal - @discount + @shipping
  end

  def create
    @address = current_customer.addresses.find_by(id: session[:checkout_address_id]) ||
               current_customer.default_shipping_address

    unless @address
      redirect_to address_checkout_path, alert: "Please select a shipping address"
      return
    end

    @coupon = Coupon.find_by(id: session[:coupon_id]) if session[:coupon_id]

    @order = build_order(@address, @coupon)

    if @order.save && @order.place!
      # Clear cart and session data
      current_cart.mark_as_converted!
      session.delete(:coupon_id)
      session.delete(:checkout_address_id)

      redirect_to order_path(@order), notice: "Order placed successfully!"
    else
      redirect_to confirm_checkout_path, alert: @order.errors.full_messages.join(", ")
    end
  end

  private

  def require_cart_items
    if current_cart.empty?
      redirect_to cart_path, alert: "Your cart is empty"
    end
  end

  def address_params
    params.require(:address).permit(
      :first_name, :last_name, :phone, :street_address,
      :apartment, :city, :state, :postal_code, :country, :is_default
    )
  end

  def build_order(address, coupon)
    order = Order.new(
      customer: current_customer,
      shipping_address: address,
      billing_address: address,
      coupon: coupon,
      payment_method: 'cod',
      notes: params[:notes]
    )

    current_cart.cart_items.each do |item|
      order.order_items.build(
        product_variant: item.product_variant,
        product_name: item.product_variant.product.name,
        variant_name: item.product_variant.name,
        sku: item.product_variant.sku,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: item.total_price
      )
    end

    order.calculate_totals!
    order
  end
end
