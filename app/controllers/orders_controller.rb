class OrdersController < ApplicationController
  before_action :require_customer

  require 'prawn'
  require 'prawn/table'

  def index
    base_scope = current_customer.orders.placed.recent.includes(:order_items)

    @status = params[:status].to_s
    allowed_statuses = Order::STATUSES

    orders_scope = case @status
    when ''
      base_scope
    when 'not_shipped'
      base_scope.where(status: %w[pending confirmed processing])
    else
      allowed_statuses.include?(@status) ? base_scope.where(status: @status) : base_scope
    end

    @pagy, @orders = pagy(orders_scope, limit: 10)
  end

  def show
    @order = current_customer.orders.find_by!(order_number: params[:order_number])
    @order_items = @order.order_items.includes(product_variant: [:product])
    @can_review = @order.can_review?
    @reviewed_variants = @order.reviews.pluck(:product_id)
  end

  def download_invoice
    @order = current_customer.orders.find_by!(order_number: params[:order_number])
    @order_items = @order.order_items.includes(product_variant: [:product])

    pdf = generate_invoice_pdf(@order, @order_items)

    send_data pdf.render,
              filename: "invoice_#{@order.order_number}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  private
  def generate_invoice_pdf(order, order_items)
    pdf = Prawn::Document.new(page_size: "A4", margin: [40, 40, 40, 40])
    pdf.font "Helvetica"
    pdf.default_leading = 2

    # =========================
    # TOP HEADER
    # =========================
    header_y = pdf.cursor

    # Left - Brand + Invoice Meta
    pdf.bounding_box([0, header_y], width: 260) do
      pdf.font_size(22) { pdf.text "Noralooks", style: :bold }
      pdf.move_down 3

      pdf.font_size(10) do
        pdf.text "Invoice #: #{order.order_number}"
        pdf.text "Invoice Date: #{order.placed_at&.strftime('%d %b %Y')}"
        pdf.text "Vendor: #{order.vendor.business_name}" if order.vendor.present?
      end
    end

    # Right - Invoice Heading + Status
    pdf.bounding_box([330, header_y], width: 180) do
      pdf.font_size(22) { pdf.text "INVOICE", style: :bold, align: :right }
      pdf.move_down 3
      pdf.font_size(10) do
        pdf.text "Status: #{order.payment_status.titleize}", align: :right
      end
    end

    pdf.move_down 30
    pdf.stroke_horizontal_rule
    pdf.move_down 20

    # =========================
    # BILL TO / SHIP TO
    # =========================
    pdf.font_size(11) { pdf.text "Billing & Shipping Details", style: :bold }
    pdf.move_down 10

    start_y = pdf.cursor

    pdf.bounding_box([0, start_y], width: 250) do
      pdf.font_size(9) do
        pdf.text "BILL TO", style: :bold
        pdf.move_down 4
        pdf.text order.shipping_address.full_name
        pdf.text order.shipping_address.street_address
        pdf.text order.shipping_address.apartment if order.shipping_address.apartment.present?
        pdf.text "#{order.shipping_address.city}, #{order.shipping_address.state} #{order.shipping_address.postal_code}"
        pdf.text order.shipping_address.country
        pdf.text "Phone: #{order.shipping_address.phone}" if order.shipping_address.phone.present?
      end
    end

    pdf.bounding_box([300, start_y], width: 250) do
      pdf.font_size(9) do
        pdf.text "SHIP TO", style: :bold
        pdf.move_down 4
        pdf.text order.shipping_address.full_name
        pdf.text order.shipping_address.street_address
        pdf.text order.shipping_address.apartment if order.shipping_address.apartment.present?
        pdf.text "#{order.shipping_address.city}, #{order.shipping_address.state} #{order.shipping_address.postal_code}"
        pdf.text order.shipping_address.country
      end
    end

    pdf.move_down 20

    # =========================
    # ORDER ITEMS TABLE
    # =========================
    pdf.font_size(11) { pdf.text "Order Summary", style: :bold }
    pdf.move_down 8

    table_data = [["Item", "Qty", "Unit Price", "Amount"]]

    order_items.each do |item|
      table_data << [
        "#{item.product_name}\n#{item.variant_name}",
        item.quantity,
        format_price(item.unit_price),
        format_price(item.total_price)
      ]
    end

    pdf.table(table_data, width: pdf.bounds.width) do
      row(0).font_style = :bold
      row(0).background_color = "EEEEEE"
      row(0).size = 10

      cells.size = 9
      cells.padding = [8, 8, 8, 8]
      cells.borders = [:bottom]
      cells.border_color = "DDDDDD"

      columns(1..3).align = :right
    end

    pdf.move_down 15

    # =========================
    # TOTALS + PAYMENT STATUS
    # =========================
    left_y = pdf.cursor

    pdf.bounding_box([0, left_y], width: 200) do
      # =========================
      # PAYMENT METHOD
      # =========================
      pdf.font_size(10) { pdf.text "Payment Information", style: :bold }
      pdf.move_down 3
      pdf.font_size(9) do
        pdf.text "Payment Method: Cash on Delivery"
      end
    end

    pdf.bounding_box([pdf.bounds.width - 150, left_y], width: 150) do
      pdf.table([
        ["Subtotal", format_price(order.subtotal)],
        ["Discount", "-#{format_price(order.discount_amount)}"],
        ["Shipping", order.shipping_amount > 0 ? format_price(order.shipping_amount) : "Free"],
        ["Tax", format_price(order.tax_amount)],
        ["Total", format_price(order.total_amount)]
      ]) do
        cells.size = 10
        cells.padding = [6, 6]
        cells.borders = []
        column(1).align = :right
        row(-1).font_style = :bold
        row(-1).size = 12
        row(-1).background_color = "F5F5F5"
      end
    end

    pdf.move_down 20

    # =========================
    # FOOTER (STICKY)
    # =========================
    pdf.bounding_box([0, 60], width: pdf.bounds.width) do
      pdf.stroke_horizontal_rule
      pdf.move_down 8
      pdf.font_size(8) do
        pdf.text "Thank you for shopping with Noralooks", align: :center
        pdf.text "This is a system generated invoice. No signature required.", align: :center
      end
    end

    pdf
  end



  def format_price(amount)
    "INR #{sprintf('%.2f', amount)}"
  end
end
