module Razorpay
  class CallbacksController < ApplicationController
    def success
      razorpay_payment_id = params[:razorpay_payment_id]
      razorpay_order_id = params[:razorpay_order_id]
      razorpay_signature = params[:razorpay_signature]

      unless razorpay_payment_id && razorpay_order_id && razorpay_signature
        redirect_to cart_path, alert: "Invalid payment response. Please contact support."
        return
      end

      # Find checkout session by Razorpay order ID
      checkout_session = ::CheckoutSession.find_by(razorpay_order_id: razorpay_order_id)

      if checkout_session.nil?
        redirect_to cart_path, alert: "Checkout session not found. Please contact support."
        return
      end

      # Get all orders associated with this checkout session
      orders = checkout_session.orders.includes(:order_items, :vendor)

      if orders.empty?
        redirect_to cart_path, alert: "Orders not found. Please contact support."
        return
      end

      # Check if already processed by webhook (all orders should be in sync)
      if orders.all? { |o| o.payment_status == "paid" }
        clear_cart_and_session(checkout_session)
        @checkout_session = checkout_session
        @orders = orders
        @total_amount = orders.sum(&:total_amount)
        render :success
        return
      end

      # Verify signature once and apply to all vendor orders
      if verify_razorpay_signature_for_orders!(checkout_session, orders, razorpay_payment_id, razorpay_order_id, razorpay_signature)
        clear_cart_and_session(checkout_session)
        @checkout_session = checkout_session
        @orders = orders
        @total_amount = orders.sum(&:total_amount)
        render :success
      else
        # Mark checkout session as failed
        checkout_session.mark_as_failed!("Payment verification failed")
        redirect_to razorpay_failure_path(error_description: "Payment verification failed")
      end
    end

    def failure
      @error_description = params[:error_description] || "Your payment could not be processed"

      # Find checkout session from session
      if session[:checkout_session_id].present?
        checkout_session = ::CheckoutSession.find_by(id: session[:checkout_session_id])

        if checkout_session
          # Mark checkout session as failed
          checkout_session.mark_as_failed!(@error_description)

          # Get orders and mark them as failed
          @orders = checkout_session.orders
          @orders.each do |order|
            order.mark_payment_failed!(@error_description) if order.payment_status == "pending"
          end

          # Calculate totals for display
          @total_amount = @orders.sum(:total_amount)
          @order_count = @orders.count
          @checkout_session = checkout_session
        else
          @orders = []
          @total_amount = 0
          @order_count = 0
          @checkout_session = nil
        end
      else
        @orders = []
        @total_amount = 0
        @order_count = 0
        @checkout_session = nil
      end
    end

    private

    # Verify Razorpay signature for multiple vendor orders
    # All orders share the same checkout session and are paid together
    def verify_razorpay_signature_for_orders!(checkout_session, orders, payment_id, order_id, signature)
      # Support both flat and nested credential structures
      creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
              Rails.application.credentials.dig(:razorpay)

      key_secret = creds&.dig(:key_secret)

      if key_secret.blank?
        Rails.logger.error "[Razorpay Callback] Key secret not configured"
        return false
      end

      # Generate signature
      generated_signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        key_secret,
        "#{order_id}|#{payment_id}"
      )

      # Verify signature
      unless ActiveSupport::SecurityUtils.secure_compare(generated_signature, signature)
        Rails.logger.error "[Razorpay Callback] Signature mismatch"
        # Log failure for all orders
        orders.each do |order|
          PaymentLog.create!(
            order: order,
            event_type: "payment.verification_failed",
            request_data: { payment_id: payment_id, signature: signature },
            status: "failed",
            error_message: "Signature mismatch"
          )
        end
        return false
      end

      # Signature valid - mark all orders and checkout session as paid
      begin
        ActiveRecord::Base.transaction do
          # Mark checkout session as paid
          checkout_session.mark_as_paid!(payment_id)

          # Mark all orders as paid
          orders.each do |order|
            # Only process orders that are still pending
            next if order.payment_status == "paid"

            order.update!(
              razorpay_payment_id: payment_id,
              payment_signature: signature,
              payment_status: "paid"
            )
            order.place!
            PaymentLog.create!(
              order: order,
              event_type: "payment.captured",
              request_data: { payment_id: payment_id, signature: signature },
              status: "success"
            )
          end
        end
        true
      rescue => e
        Rails.logger.error "[Razorpay Callback] Failed to process payment: #{e.message}"
        false
      end
    end

    def clear_cart_and_session(checkout_session)
      # Clear the cart associated with this checkout session
      if checkout_session.cart_token.present?
        cart = Cart.find_by(token: checkout_session.cart_token)
        cart&.mark_as_converted!
        session.delete(:cart_token) if session[:cart_token] == checkout_session.cart_token
      end

      # Clear other session data
      session.delete(:checkout_address_id)
      session.delete(:checkout_session_id)
      session.delete(:razorpay_order_ids)
      session.delete(:coupon_id)
    end

    def clear_checkout_session
      session.delete(:checkout_address_id)
      session.delete(:checkout_session_id)
      session.delete(:razorpay_order_ids)
      session.delete(:coupon_id)
    end
  end
end
