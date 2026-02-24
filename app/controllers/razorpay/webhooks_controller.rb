module Razorpay
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_webhook_signature

    def handle
      payload = request.body.read
      event = JSON.parse(payload)
      event_type = event["event"]

      Rails.logger.info "[Razorpay Webhook] Received: #{event_type}"

      case event_type
      when "payment.captured"
        handle_payment_captured(event["payload"]["payment"]["entity"])
      when "payment.failed"
        handle_payment_failed(event["payload"]["payment"]["entity"])
      when "order.paid"
        handle_order_paid(event["payload"]["order"]["entity"])
      when "refund.processed"
        handle_refund_processed(event["payload"]["refund"]["entity"])
      else
        Rails.logger.info "[Razorpay Webhook] Unhandled event type: #{event_type}"
      end

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error "[Razorpay Webhook] Invalid JSON: #{e.message}"
      head :bad_request
    rescue => e
      Rails.logger.error "[Razorpay Webhook] Processing error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      head :internal_server_error
    end

    private

    def verify_webhook_signature
      webhook_secret = Rails.application.credentials.dig(:razorpay, :webhook_secret)
      received_signature = request.headers["X-Razorpay-Signature"]

      unless received_signature.present?
        Rails.logger.error "[Razorpay Webhook] Missing signature"
        head :unauthorized and return
      end

      expected_signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        webhook_secret,
        request.body.read
      )

      request.body.rewind

      unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, received_signature)
        Rails.logger.error "[Razorpay Webhook] Signature verification failed"
        head :unauthorized and return
      end
    end

    def handle_payment_captured(payment)
      # Find ALL orders associated with this Razorpay order (multi-vendor support)
      orders = Order.where(razorpay_order_id: payment["order_id"])

      if orders.empty?
        Rails.logger.error "[Razorpay Webhook] Orders not found for order_id: #{payment['order_id']}"
        return
      end

      # Calculate total amount across all vendor orders
      total_expected_amount = orders.sum { |o| (o.total_amount * 100).to_i }

      # Verify total amount matches
      if payment["amount"] != total_expected_amount
        Rails.logger.error "[Razorpay Webhook] Amount mismatch for batch: expected #{total_expected_amount}, got #{payment['amount']}"
        orders.each do |order|
          PaymentLog.create!(
            order: order,
            event_type: "webhook.amount_mismatch",
            request_data: payment,
            status: "failed",
            error_message: "Batch amount mismatch: expected #{total_expected_amount}, got #{payment['amount']}"
          )
        end
        return
      end

      begin
        ActiveRecord::Base.transaction do
          orders.each do |order|
            # Idempotency check - skip already paid orders
            next if order.payment_status == "paid"

            order.update!(
              razorpay_payment_id: payment["id"],
              payment_status: "paid"
            )
            order.place!

            PaymentLog.create!(
              order: order,
              event_type: "webhook.payment.captured",
              response_data: payment,
              status: "success"
            )
          end
        end

        Rails.logger.info "[Razorpay Webhook] #{orders.count} order(s) marked as paid for batch #{payment['order_id']}"
      rescue => e
        Rails.logger.error "[Razorpay Webhook] Failed to process payment: #{e.message}"
        orders.each do |order|
          PaymentLog.create!(
            order: order,
            event_type: "webhook.payment.captured",
            response_data: payment,
            status: "failed",
            error_message: e.message
          )
        end
      end
    end

    def handle_payment_failed(payment)
      # Find ALL orders associated with this Razorpay order (multi-vendor support)
      orders = Order.where(razorpay_order_id: payment["order_id"])
      return if orders.empty?

      orders.each do |order|
        order.mark_payment_failed!(payment["error_description"])
      end
      Rails.logger.info "[Razorpay Webhook] #{orders.count} order(s) marked as failed"
    end

    def handle_order_paid(order_data)
      # Find ALL orders associated with this Razorpay order (multi-vendor support)
      orders = Order.where(razorpay_order_id: order_data["id"])
      return if orders.empty?

      orders.each do |order|
        next if order.payment_status == "paid"

        order.update!(payment_status: "paid")
        order.place! unless order.placed?

        PaymentLog.create!(
          order: order,
          event_type: "webhook.order.paid",
          response_data: order_data,
          status: "success"
        )
      end
    end

    def handle_refund_processed(refund)
      order = Order.find_by(razorpay_payment_id: refund["payment_id"])
      return unless order

      order.update!(payment_status: "refunded")
      PaymentLog.create!(
        order: order,
        event_type: "webhook.refund.processed",
        response_data: refund,
        status: "success"
      )

      Rails.logger.info "[Razorpay Webhook] Order #{order.id} marked as refunded"
    end
  end
end
