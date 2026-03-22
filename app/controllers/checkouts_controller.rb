class CheckoutsController < ApplicationController
  before_action :require_customer
  before_action :require_cart_items

  def show
    @addresses = current_customer.addresses.default_first
    
    # If no addresses exist, redirect to address page to add one
    if @addresses.empty?
      redirect_to new_address_path(redirect_to: 'checkout') and return
    end
    
    @address = current_customer.addresses.find_by(id: session[:checkout_address_id]) ||
               current_customer.default_shipping_address

    # Calculate order totals (same as old confirm action)
    @coupon = Coupon.find_by(id: session[:coupon_id]) if session[:coupon_id]
    @cart = current_cart
    @subtotal = @cart.subtotal
    @discount = @coupon&.calculate_discount(@subtotal) || 0

    # Group cart items by vendor for per-vendor breakdown
    @items_by_vendor = @cart.cart_items.includes(product_variant: { product: :vendor }).group_by do |item|
      item.product_variant.product.vendor
    end

    # Calculate per-vendor estimates
    @vendor_estimates = calculate_vendor_estimates(@items_by_vendor, @subtotal, @discount)

    # Total shipping is sum of per-vendor shipping
    @shipping = @vendor_estimates.sum { |_, est| est[:shipping] }
    @tax = calculate_cart_hsn_tax(@subtotal - @discount)
    @total = (@subtotal - @discount) + @shipping + @tax

    # Pass Razorpay key to view for payment initialization
    creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
            Rails.application.credentials.dig(:razorpay)
    @razorpay_key_id = creds&.dig(:key_id)
  end

  def save_address
    if params[:address_token].present?
      @address = current_customer.addresses.find_by!(token: params[:address_token])
      session[:checkout_address_id] = @address.id

      respond_to do |format|
        format.html { redirect_to checkout_path }
        format.json {
          render json: {
            success: true,
            address: {
              id: @address.id,
              full_name: @address.full_name,
              full_address: @address.full_address,
              phone: @address.phone,
              is_default: @address.is_default?
            }
          }
        }
      end
    else
      @address = current_customer.addresses.build(address_params)
      if @address.save
        # Set as default if it's the first address or if explicitly requested
        if current_customer.addresses.count == 1 || @address.is_default?
          session[:checkout_address_id] = @address.id
        else
          # If not default, still select it for this checkout
          session[:checkout_address_id] = @address.id
        end

        respond_to do |format|
          format.html { redirect_to checkout_path }
          format.json {
            render json: {
              success: true,
              address: {
                id: @address.id,
                full_name: @address.full_name,
                full_address: @address.full_address,
                phone: @address.phone,
                is_default: @address.is_default?
              }
            }
          }
        end
      else
        @addresses = current_customer.addresses.default_first
        respond_to do |format|
          format.html { render :address, status: :unprocessable_entity }
          format.json { render json: { success: false, errors: @address.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end
  end

  def confirm
    # Redirect to simplified checkout (merged show + confirm into one page)
    redirect_to checkout_path
  end

  def create
    @address = current_customer.addresses.find_by(id: session[:checkout_address_id]) ||
               current_customer.default_shipping_address

    unless @address
      redirect_to address_checkout_path, alert: "Please select a shipping address"
      return
    end

    # Check if any payment method is enabled
    store_setting = StoreSetting.instance
    unless store_setting.any_payment_method_enabled?
      respond_to do |format|
        format.html { redirect_to checkout_path, alert: "Checkout is temporarily unavailable. Please try again later." }
        format.json { render json: { success: false, error: "Checkout is temporarily unavailable" }, status: :service_unavailable }
      end
      return
    end

    @coupon = Coupon.find_by(id: session[:coupon_id]) if session[:coupon_id]
    payment_method = params[:payment_method] || "cod"

    # Validate payment method
    unless Order::PAYMENT_METHODS.include?(payment_method)
      respond_to do |format|
        format.html { redirect_to checkout_path, alert: "Invalid payment method" }
        format.json { render json: { success: false, error: "Invalid payment method" }, status: :unprocessable_entity }
      end
      return
    end

    # Validate that selected payment method is enabled
    if payment_method == "razorpay" && !store_setting.razorpay_enabled?
      respond_to do |format|
        format.html { redirect_to checkout_path, alert: "Online payment is currently unavailable" }
        format.json { render json: { success: false, error: "Online payment is currently unavailable" }, status: :unprocessable_entity }
      end
      return
    end

    if payment_method == "cod" && !store_setting.cod_enabled?
      respond_to do |format|
        format.html { redirect_to checkout_path, alert: "Cash on delivery is currently unavailable" }
        format.json { render json: { success: false, error: "Cash on delivery is currently unavailable" }, status: :unprocessable_entity }
      end
      return
    end

    # Group cart items by vendor for order splitting
    items_by_vendor = current_cart.cart_items.includes(product_variant: :product).group_by do |item|
      item.product_variant.product.vendor_id
    end

    cart_subtotal = current_cart.subtotal
    total_discount = @coupon&.calculate_discount(cart_subtotal) || 0
    batch_id = SecureRandom.uuid

    orders = []
    checkout_session = nil
    begin
      ActiveRecord::Base.transaction do
        # Create vendor orders first
        items_by_vendor.each_with_index do |(vendor_id, items), index|
          # First vendor gets full discount for fixed amount coupons
          is_first_vendor = index == 0
          order = build_vendor_order(vendor_id, items, @address, @coupon, batch_id, cart_subtotal, total_discount, payment_method, is_first_vendor: is_first_vendor)
          order.save!

          if payment_method == "cod"
            # COD: place immediately
            order.place!
          end

          orders << order
        end

        if payment_method == "razorpay"
          # Create a CheckoutSession to group all vendor orders under one payment
          total_amount = orders.sum(&:total_amount)
          checkout_session = CheckoutSession.create!(
            customer: current_customer,
            batch_id: batch_id,
            payment_method: "razorpay",
            status: "pending",
            total_amount: total_amount,
            notes: params[:notes],
            cart_token: current_cart&.token
          )

          # Link all orders to the checkout session
          orders.each do |order|
            order.update!(checkout_session: checkout_session)
          end

          # Create a SINGLE Razorpay order for the total amount
          razorpay_order = create_master_razorpay_order!(checkout_session, total_amount)

          # Update checkout session with Razorpay order ID
          checkout_session.update!(razorpay_order_id: razorpay_order.id)

          # Log payment initiation for each order
          orders.each do |order|
            PaymentLog.create!(
              order: order,
              event_type: "payment.initiated",
              response_data: razorpay_order.attributes,
              status: "success"
            )
          end

          # Store checkout session ID in session for callback
          session[:checkout_session_id] = checkout_session.id

          # Return JSON for Razorpay checkout
          razorpay_creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
                          Rails.application.credentials.dig(:razorpay)

          render json: {
            success: true,
            razorpay_key: razorpay_creds&.dig(:key_id),
            # Single Razorpay order for all vendor orders
            razorpay_order_id: razorpay_order.id,
            amount: (total_amount * 100).to_i,
            currency: "INR",
            name: "Noralooks - #{orders.size} Order#{'s' if orders.size > 1}",
            description: "#{orders.size} vendor order#{'s' if orders.size > 1}",
            prefill: {
              name: current_customer&.full_name,
              email: current_customer&.email,
              contact: current_customer&.phone || @address.phone
            },
            notes: {
              internal_order_ids: orders.map(&:id).join(","),
              order_numbers: orders.map(&:order_number).join(","),
              batch_id: batch_id,
              vendor_count: orders.size
            },
            # Include per-vendor breakdown for display
            vendor_orders: orders.map do |order|
              {
                order_id: order.id,
                order_number: order.order_number,
                vendor_id: order.vendor_id,
                amount: order.total_amount,
                item_count: order.order_items.count
              }
            end
          }
          return
        else
          # COD flow
          current_cart.mark_as_converted!
          session.delete(:coupon_id)
          session.delete(:checkout_address_id)
        end
      end

      # Success - redirect to order(s)
      if orders.size == 1
        redirect_to order_path(orders.first), notice: "Order placed successfully!"
      else
        redirect_to orders_path, notice: "#{orders.size} orders placed successfully!"
      end
    rescue => e
      Rails.logger.error "Checkout error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")

      respond_to do |format|
        format.html { redirect_to checkout_path, alert: "Error: #{e.message}" }
        format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  private

  def require_cart_items
    if current_cart.empty?
      redirect_to cart_path, alert: "Your cart is empty"
    end
  end

  # Create a single Razorpay order for multiple vendor orders
  # This ensures one payment processes all vendor orders together (Amazon-style)
  def create_master_razorpay_order!(checkout_session, total_amount)
    require "razorpay"

    # Configure Razorpay credentials
    creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
            Rails.application.credentials.dig(:razorpay)

    Razorpay.setup(creds&.dig(:key_id), creds&.dig(:key_secret))

    # Generate a shorter receipt (max 40 chars for Razorpay)
    receipt = "CS#{checkout_session.batch_id[0..7]}#{Time.current.strftime('%y%m%d%H%M')}"

    # Get orders associated with this checkout session
    orders = checkout_session.orders

    Razorpay::Order.create(
      amount: (total_amount * 100).to_i, # Razorpay expects paise
      currency: "INR",
      receipt: receipt,
      notes: {
        checkout_session_id: checkout_session.id,
        batch_id: checkout_session.batch_id,
        order_ids: orders.map(&:id).join(","),
        order_numbers: orders.map(&:order_number).join(","),
        vendor_ids: orders.map(&:vendor_id).join(","),
        customer_email: current_customer&.email,
        customer_id: current_customer&.id
      }
    )
  rescue => e
    Rails.logger.error "[Checkout] Failed to create Razorpay order: #{e.message}"
    raise "Payment initialization failed: #{e.message}"
  end

  def address_params
    params.require(:address).permit(
      :first_name, :last_name, :phone, :street_address,
      :apartment, :city, :state, :postal_code, :country, :is_default
    )
  end

  def build_vendor_order(vendor_id, items, address, coupon, batch_id, cart_subtotal, total_discount, payment_method = "cod", is_first_vendor: false)
    vendor_subtotal = items.sum(&:total_price)

    # Calculate discount for this vendor's items
    # For fixed amount coupons, apply full discount to first vendor only
    # For percentage coupons, split proportionally among all vendors
    vendor_discount = if cart_subtotal > 0 && total_discount > 0
      if coupon&.fixed?
        # Fixed amount: apply to first vendor only
        is_first_vendor ? total_discount : 0
      else
        # Percentage: split proportionally
        (total_discount * (vendor_subtotal.to_f / cart_subtotal.to_f)).round(2)
      end
    else
      0
    end

    order = Order.new(
      customer: current_customer,
      vendor_id: vendor_id,
      shipping_address: address,
      billing_address: address,
      coupon: vendor_discount > 0 ? coupon : nil,
      payment_method: payment_method,
      notes: params[:notes],
      checkout_batch_id: batch_id
    )

    items.each do |item|
      product = item.product_variant.product
      order.order_items.build(
        product_variant: item.product_variant,
        vendor_id: vendor_id,
        product_name: product.name,
        variant_name: item.product_variant.name,
        sku: item.product_variant.sku,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: item.total_price,
        return_in_days: product.return_in_days,
        exchange_in_days: product.exchange_in_days
      )
    end

    # Calculate totals with discount override
    order.subtotal = vendor_subtotal
    order.discount_amount = vendor_discount
    discounted = vendor_subtotal - vendor_discount
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

  # Calculate per-vendor estimates for checkout display
  # Each vendor gets their own shipping calculation based on their subtotal
  def calculate_vendor_estimates(items_by_vendor, cart_subtotal, total_discount)
    estimates = {}

    items_by_vendor.each_with_index do |(vendor, items), index|
      vendor_subtotal = items.sum(&:total_price)

      # Calculate discount for this vendor (percentage split)
      vendor_discount = if cart_subtotal > 0 && total_discount > 0
        if @coupon&.fixed?
          # Fixed amount: apply to first vendor only
          index == 0 ? total_discount : 0
        else
          # Percentage: split proportionally
          (total_discount * (vendor_subtotal.to_f / cart_subtotal.to_f)).round(2)
        end
      else
        0
      end

      discounted_subtotal = vendor_subtotal - vendor_discount

      # Calculate shipping per vendor (FREE if above StoreSetting threshold)
      shipping = Order.calculate_shipping_amount(discounted_subtotal)

      # Calculate tax per vendor
      vendor_tax = items.sum do |item|
        rate = item.product_variant&.product&.hsn_code&.gst_rate || 3.0
        (item.total_price.to_f * rate / 100.0 * (discounted_subtotal.to_f / vendor_subtotal.to_f)).round(2)
      end

      total = discounted_subtotal + shipping + vendor_tax

      estimates[vendor] = {
        items: items,
        subtotal: vendor_subtotal,
        discount: vendor_discount,
        shipping: shipping,
        tax: vendor_tax,
        total: total,
        item_count: items.sum(&:quantity)
      }
    end

    estimates
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
