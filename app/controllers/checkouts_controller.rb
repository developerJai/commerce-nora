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
    if params[:address_token].present?
      @address = current_customer.addresses.find_by!(token: params[:address_token])
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
    discounted_subtotal = @subtotal - @discount
    @shipping = Order.calculate_shipping_amount(discounted_subtotal)
    @tax = calculate_cart_hsn_tax(discounted_subtotal)
    @total = discounted_subtotal + @shipping + @tax
  end

  def create
    @address = current_customer.addresses.find_by(id: session[:checkout_address_id]) ||
               current_customer.default_shipping_address

    unless @address
      redirect_to address_checkout_path, alert: "Please select a shipping address"
      return
    end

    @coupon = Coupon.find_by(id: session[:coupon_id]) if session[:coupon_id]

    # Group cart items by vendor for order splitting
    items_by_vendor = current_cart.cart_items.includes(product_variant: :product).group_by do |item|
      item.product_variant.product.vendor_id
    end

    cart_subtotal = current_cart.subtotal
    total_discount = @coupon&.calculate_discount(cart_subtotal) || 0
    batch_id = SecureRandom.uuid

    orders = []
    begin
      ActiveRecord::Base.transaction do
        items_by_vendor.each do |vendor_id, items|
          order = build_vendor_order(vendor_id, items, @address, @coupon, batch_id, cart_subtotal, total_discount)
          order.save!
          order.place!
          orders << order
        end

        current_cart.mark_as_converted!
        session.delete(:coupon_id)
        session.delete(:checkout_address_id)
      end

      if orders.size == 1
        redirect_to order_path(orders.first), notice: "Order placed successfully!"
      else
        redirect_to orders_path, notice: "#{orders.size} orders placed successfully!"
      end
    rescue => e
      redirect_to confirm_checkout_path, alert: e.message
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

  def build_vendor_order(vendor_id, items, address, coupon, batch_id, cart_subtotal, total_discount)
    vendor_subtotal = items.sum(&:total_price)

    # Proportional discount for this vendor's items
    proportional_discount = if cart_subtotal > 0 && total_discount > 0
      (total_discount * (vendor_subtotal.to_f / cart_subtotal.to_f)).round(2)
    else
      0
    end

    order = Order.new(
      customer: current_customer,
      vendor_id: vendor_id,
      shipping_address: address,
      billing_address: address,
      coupon: proportional_discount > 0 ? coupon : nil,
      payment_method: 'cod',
      notes: params[:notes],
      checkout_batch_id: batch_id
    )

    items.each do |item|
      order.order_items.build(
        product_variant: item.product_variant,
        vendor_id: vendor_id,
        product_name: item.product_variant.product.name,
        variant_name: item.product_variant.name,
        sku: item.product_variant.sku,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: item.total_price
      )
    end

    # Calculate totals with proportional discount override
    order.subtotal = vendor_subtotal
    order.discount_amount = proportional_discount
    discounted = vendor_subtotal - proportional_discount
    order.shipping_amount = Order.calculate_shipping_amount(discounted)
    order.tax_amount = calculate_order_hsn_tax(order.order_items, discounted, vendor_subtotal)
    order.total_amount = discounted + order.shipping_amount + order.tax_amount
    order
  end

  # HSN-based tax calculation for the confirm page (from cart items)
  def calculate_cart_hsn_tax(discounted_subtotal)
    cart_subtotal = current_cart.subtotal
    return 0 if cart_subtotal <= 0

    total_tax = current_cart.cart_items.includes(product_variant: { product: :hsn_code }).sum do |item|
      rate = item.product_variant&.product&.hsn_code&.gst_rate || 3.0
      (item.total_price.to_f * rate / 100.0)
    end

    ratio = discounted_subtotal.to_f / cart_subtotal.to_f
    (total_tax * ratio).round(2)
  end

  # HSN-based tax calculation for a vendor's order items
  def calculate_order_hsn_tax(order_items, discounted_subtotal, vendor_subtotal)
    return 0 if vendor_subtotal <= 0

    total_tax = order_items.sum do |item|
      rate = item.product_variant&.product&.hsn_code&.gst_rate || 3.0
      (item.total_price.to_f * rate / 100.0)
    end

    ratio = discounted_subtotal.to_f / vendor_subtotal.to_f
    (total_tax * ratio).round(2)
  end
end
