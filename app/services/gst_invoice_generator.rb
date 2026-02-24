# frozen_string_literal: true

# Unified GST Invoice Generator Service
# Generates consistent GST invoices for Customer, Vendor, and Admin views
class GstInvoiceGenerator
  require "prawn"
  require "prawn/table"

  def self.generate(order, order_items, type: :customer)
    new(order, order_items, type).generate
  end

  def initialize(order, order_items, type)
    @order = order
    @order_items = order_items
    @type = type # :customer, :vendor, :admin
    @pdf = Prawn::Document.new(page_size: "A4", margin: [ 30, 30, 30, 30 ])
    @pdf.font "Helvetica"
    @store_setting = StoreSetting.instance
  end

  def generate
    add_header
    add_party_details
    add_items_table
    add_tax_summary
    add_totals
    add_payment_info
    add_footer

    @pdf
  end

  private

  def add_header
    header_y = @pdf.cursor

    # Left side - Company Info
    @pdf.bounding_box([ 0, header_y ], width: 260) do
      @pdf.font_size(20) { @pdf.text "Noralooks", style: :bold }
      @pdf.move_down 5
      @pdf.font_size(9) do
        invoice_type_text = case @type
        when :vendor then "VENDOR INVOICE"
        when :admin then "ADMIN INVOICE"
        else "GST INVOICE"
        end
        @pdf.text invoice_type_text, style: :bold, color: "059669"
        @pdf.text "Invoice #: #{@order.order_number}"
        @pdf.text "Date: #{format_date(@order.placed_at || @order.created_at)}"
        if company_gstin.present?
          @pdf.text "Company GSTIN: #{company_gstin}", style: :bold
        end
      end
    end

    # Right side - Invoice Type & QR placeholder
    @pdf.bounding_box([ 340, header_y ], width: 180) do
      @pdf.font_size(16) { @pdf.text "TAX INVOICE", style: :bold, align: :right }
      @pdf.move_down 5
      @pdf.font_size(9) do
        recipient_text = case @type
        when :vendor then "Vendor Copy"
        when :admin then "Admin Copy"
        else "Original for Recipient"
        end
        @pdf.text recipient_text, align: :right, style: :italic
        @pdf.text "Status: #{@order.payment_status.titleize}", align: :right
        if @order.tax_amount.to_f > 0
          @pdf.text "Total GST: Rs. #{format_amount(@order.tax_amount)}", align: :right, color: "059669"
        end
      end
    end

    @pdf.move_down 25
    @pdf.stroke_horizontal_rule
    @pdf.move_down 15
  end

  def add_party_details
    details_y = @pdf.cursor

    # Sold By (Vendor) - Left Column
    @pdf.bounding_box([ 0, details_y ], width: 255) do
      @pdf.font_size(10) { @pdf.text "Sold By:", style: :bold, color: "1E40AF" }
      @pdf.move_down 5
      @pdf.font_size(9) do
        if @order.vendor.present?
          @pdf.text @order.vendor.business_name, style: :bold
          if vendor_gstin.present?
            @pdf.text "GSTIN: #{vendor_gstin}", style: :bold, color: "059669"
          end
          @pdf.text "Email: #{@order.vendor.email}" if @order.vendor.email.present?
          @pdf.text "Phone: #{@order.vendor.phone}" if @order.vendor.respond_to?(:phone) && @order.vendor.phone.present?
          if @order.vendor.respond_to?(:address_line1) && @order.vendor.address_line1.present?
            @pdf.move_down 3
            @pdf.text @order.vendor.address_line1
            @pdf.text "#{@order.vendor.city}, #{@order.vendor.state} - #{@order.vendor.pincode}"
          end
        else
          @pdf.text "Noralooks Marketplace", style: :bold
          @pdf.text "Company GSTIN: #{company_gstin}" if company_gstin.present?
        end
      end
    end

    # Bill To (Customer) - Right Column
    @pdf.bounding_box([ 265, details_y ], width: 255) do
      @pdf.font_size(10) { @pdf.text "Bill To:", style: :bold, color: "1E40AF" }
      @pdf.move_down 5
      @pdf.font_size(9) do
        if @order.shipping_address
          @pdf.text @order.shipping_address.full_name, style: :bold
          @pdf.text @order.customer.email if @order.customer.present?
          @pdf.move_down 3
          @pdf.text @order.shipping_address.street_address
          @pdf.text @order.shipping_address.apartment if @order.shipping_address.apartment.present?
          @pdf.text "#{@order.shipping_address.city}, #{@order.shipping_address.state} - #{@order.shipping_address.postal_code}"
          @pdf.text "#{@order.shipping_address.country}"
          @pdf.text "Phone: #{@order.shipping_address.phone}" if @order.shipping_address.phone.present?
        elsif @order.customer
          @pdf.text @order.customer.full_name, style: :bold
          @pdf.text @order.customer.email
        end
      end
    end

    @pdf.move_down 25
  end

  def add_items_table
    @pdf.font_size(10) { @pdf.text "Item Details", style: :bold }
    @pdf.move_down 8

    # Table headers with GST columns
    table_data = [ [ "Item", "HSN", "Qty", "Rate", "Disc", "GST%", "Taxable", "GST Amt", "Total" ] ]

    @order_items.each do |item|
      # Calculate per-item GST
      item_gst = calculate_item_gst(item)
      taxable_amount = item.total_price - (item_gst * item.quantity)

      table_data << [
        truncate_string(item.product_name, 30),
        item.sku || "-",
        item.quantity,
        format_amount(item.unit_price),
        "-", # Discounts are applied at order level, not per item
        "#{item_gst_rate(item)}%",
        format_amount(taxable_amount),
        format_amount(item_gst * item.quantity),
        format_amount(item.total_price + (item_gst * item.quantity))
      ]
    end

    @pdf.table(table_data, width: @pdf.bounds.width, header: true) do
      row(0).font_style = :bold
      row(0).background_color = "DBEAFE"  # Light blue
      row(0).size = 8

      cells.size = 8
      cells.padding = [ 4, 4 ]
      cells.borders = [ :bottom ]
      cells.border_color = "BFDBFE"

      columns(2..8).align = :right
      column(0).width = 110
      column(1).width = 60
    end

    @pdf.move_down 15
  end

  def add_tax_summary
    return if @order.tax_amount.to_f <= 0

    @pdf.font_size(10) { @pdf.text "Tax Summary", style: :bold }
    @pdf.move_down 5

    tax_data = @order.tax_breakdown_display
    if tax_data.present? && tax_data["summary"].present?
      tax_rows = [ [ "Tax Rate", "Taxable Value", "CGST", "SGST", "IGST", "Total Tax" ] ]

      tax_data["summary"].each do |tax|
        tax_amount = tax["total_tax"].to_f
        # Split tax into CGST and SGST (50% each for intra-state)
        cgst = sgst = tax_amount / 2

        tax_rows << [
          "#{tax['rate']}%",
          format_amount(tax["total_taxable"]),
          format_amount(cgst),
          format_amount(sgst),
          "-",  # IGST column (0 for intra-state)
          format_amount(tax_amount)
        ]
      end

      # Total row
      total_taxable = tax_data["summary"].sum { |t| t["total_taxable"].to_f }
      total_cgst = total_sgst = @order.tax_amount.to_f / 2

      tax_rows << [
        "Total",
        format_amount(total_taxable),
        format_amount(total_cgst),
        format_amount(total_sgst),
        "-",
        format_amount(@order.tax_amount)
      ]

      @pdf.table(tax_rows, width: @pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = "F3F4F6"
        row(-1).font_style = :bold
        row(-1).background_color = "F3F4F6"

        cells.size = 9
        cells.padding = [ 5, 5 ]
        cells.borders = [ :bottom ]
        cells.border_color = "E5E7EB"
        columns(1..5).align = :right
      end
    end

    @pdf.move_down 15
  end

  def add_totals
    left_y = @pdf.cursor

    # Amount in words (left side)
    @pdf.bounding_box([ 0, left_y ], width: 300) do
      @pdf.font_size(9) do
        @pdf.text "Amount in Words:", style: :bold
        @pdf.move_down 3
        @pdf.text amount_in_words(@order.total_amount), size: 8, style: :italic
      end
    end

    # Totals table (right side)
    @pdf.bounding_box([ @pdf.bounds.width - 200, left_y ], width: 200) do
      if @type == :vendor
        add_vendor_totals
      else
        add_customer_totals
      end
    end

    @pdf.move_down 20
  end

  def add_customer_totals
    totals = [
      [ "Subtotal:", format_amount(@order.subtotal) ],
      [ "Discount:", "-#{format_amount(@order.discount_amount)}" ],
      [ "Shipping:", @order.shipping_amount.to_f > 0 ? format_amount(@order.shipping_amount) : "Free" ]
    ]

    if @order.tax_amount.to_f > 0
      totals << [ "CGST:", format_amount(@order.tax_amount.to_f / 2) ]
      totals << [ "SGST:", format_amount(@order.tax_amount.to_f / 2) ]
    end

    totals << [ "", "" ]
    totals << [ "Grand Total:", format_amount(@order.total_amount) ]

    @pdf.table(totals, width: 200) do
      cells.size = 9
      cells.padding = [ 4, 6 ]
      cells.borders = []
      column(1).align = :right
      row(-1).font_style = :bold
      row(-1).size = 11
      row(-1).text_color = "059669"
      row(-2).borders = [ :top ]
      row(-2).border_color = "D1D5DB"
    end
  end

  def add_vendor_totals
    # Get fee breakdown - calculate if not already stored
    fee_data = @order.fee_breakdown_display || {}

    # If fee data is not available, calculate projected fees
    if fee_data.blank? || fee_data.dig("platform_fee", "commission_amount").to_f == 0
      config = PlatformFeeConfig.current
      fees = config.calculate_fees(@order.total_amount)

      platform_fee = fees[:platform_fee]
      gateway_fee = fees[:gateway_fee]
      gateway_gst = fees[:gateway_gst]
      commission_rate = config.platform_commission_percent
      gateway_rate = config.gateway_fee_percent
    else
      platform_fee = fee_data.dig("platform_fee", "commission_amount") || @order.platform_fee_amount || 0
      gateway_fee = fee_data.dig("gateway_fee", "base_gateway_fee") || @order.gateway_fee_amount || 0
      gateway_gst = fee_data.dig("gateway_fee", "gst_on_gateway_fee") || @order.gateway_gst_amount || 0
      commission_rate = fee_data.dig("platform_fee", "commission_rate") || PlatformFeeConfig.current&.platform_commission_percent || 0
      gateway_rate = fee_data.dig("gateway_fee", "gateway_rate") || PlatformFeeConfig.current&.gateway_fee_percent || 0
    end

    # For COD orders, gateway fee is 0 (no online payment)
    if @order.cod?
      gateway_fee = 0
      gateway_gst = 0
      gateway_rate = 0
    end

    totals = [
      [ "Order Total:", format_amount(@order.total_amount) ],
      [ "", "" ],
      [ "Platform Fee (#{commission_rate}%):", "-#{format_amount(platform_fee)}" ],
      [ "  (Commission charged by platform)", "" ],
      [ "Gateway Fee (#{gateway_rate}%):", "-#{format_amount(gateway_fee)}" ],
      [ "  (Payment processing fee)", "" ],
      [ "GST on Gateway:", "-#{format_amount(gateway_gst)}" ],
      [ "  (18% GST on gateway fee)", "" ],
      [ "", "" ],
      [ "Total Platform Deductions:", "-#{format_amount(platform_fee + gateway_fee + gateway_gst)}" ],
      [ "  (Amount retained by Noralooks)", "" ],
      [ "", "" ]
    ]

    # Payout status
    payout_text = case @order.payout_status
    when "pending" then "Pending"
    when "requested" then "Requested"
    when "approved" then "Approved"
    when "paid" then "Paid"
    else "Pending"
    end

    # Calculate net earnings if not stored
    net_earnings = if @order.vendor_earnings.present? && @order.vendor_earnings > 0
                     @order.vendor_earnings
    else
                     @order.total_amount - platform_fee - gateway_fee - gateway_gst
    end

    totals << [ "Your Net Earnings:", format_amount(net_earnings) ]
    totals << [ "  (Amount you will receive)", "" ]
    totals << [ "Payout Status:", payout_text ]

    @pdf.table(totals, width: 220) do
      cells.size = 8
      cells.padding = [ 2, 5 ]
      cells.borders = []
      column(1).align = :right

      # Style main fee rows in red (indices of actual amounts)
      [ 2, 4, 6, 9 ].each do |row|
        cells[row, 1].text_color = "DC2626"
        cells[row, 0].font_style = :bold
      end

      # Style description rows in gray and smaller
      [ 3, 5, 7, 10, 12 ].each do |row|
        cells[row, 0].text_color = "6B7280"
        cells[row, 0].size = 7
        cells[row, 0].font_style = :italic
      end

      # Style earnings in green and bold
      row(-3).font_style = :bold
      row(-3).size = 10
      row(-3).text_color = "059669"

      # Top border for earnings
      row(-3).borders = [ :top ]
      row(-3).border_color = "D1D5DB"
    end
  end

  def add_payment_info
    @pdf.font_size(9) { @pdf.text "Payment Information", style: :bold }
    @pdf.move_down 3

    @pdf.font_size(8) do
      method_text = case @order.payment_method
      when "razorpay" then "Online Payment (Razorpay)"
      when "cod" then "Cash on Delivery"
      else @order.payment_method&.titleize || "Not specified"
      end

      @pdf.text "Payment Method: #{method_text}"
      @pdf.text "Payment Status: #{@order.payment_status.titleize}"

      if @order.razorpay? && @order.razorpay_payment_id.present?
        @pdf.text "Razorpay Payment ID: #{@order.razorpay_payment_id}", style: :bold
      end

      if @order.razorpay? && @order.razorpay_order_id.present?
        @pdf.text "Razorpay Order ID: #{@order.razorpay_order_id}"
      end
    end

    @pdf.move_down 15
  end

  def add_footer
    # Add fee explanation for vendors
    if @type == :vendor
      @pdf.move_down 10
      @pdf.font_size(7) do
        @pdf.text "Fee Structure Explanation:", style: :bold, color: "374151"
        @pdf.move_down 2
        @pdf.text "• Platform Fee: Commission charged by Noralooks for using the marketplace platform", size: 6, color: "4B5563"
        @pdf.text "• Gateway Fee: Charged by Razorpay for processing online payments", size: 6, color: "4B5563"
        @pdf.text "• GST on Gateway: 18% GST applied on the payment gateway fee (as per government regulations)", size: 6, color: "4B5563"
        @pdf.text "• Your Net Earnings: Final amount you receive after all platform deductions", size: 6, color: "4B5563"
        @pdf.move_down 5
      end
    end

    @pdf.bounding_box([ 0, 40 ], width: @pdf.bounds.width) do
      @pdf.stroke_horizontal_rule
      @pdf.move_down 5

      @pdf.font_size(7) do
        if @order.tax_amount.to_f > 0
          @pdf.text "This is a GST Invoice as per GST Act. #{gst_eligibility_notice}", align: :center
          if vendor_gstin.present?
            @pdf.text "Vendor GSTIN: #{vendor_gstin} | Company GSTIN: #{company_gstin}", align: :center, size: 6
          end
          @pdf.move_down 3
        end
        @pdf.text "Thank you for shopping with Noralooks! This is a computer generated invoice.", align: :center
        @pdf.text "For any queries, please contact support@noralooks.com", align: :center, size: 6
      end
    end
  end

  # Helper methods
  def format_date(datetime)
    datetime&.strftime("%d %b %Y") || "-"
  end

  def format_amount(amount)
    "Rs. #{sprintf('%.2f', amount.to_f)}"
  end

  def calculate_item_gst(item)
    if item.respond_to?(:gst_amount) && item.gst_amount.to_f > 0
      item.gst_amount / item.quantity
    elsif @order.tax_amount.to_f > 0 && @order.subtotal.to_f > 0
      (item.total_price / @order.subtotal) * @order.tax_amount / item.quantity
    else
      0
    end
  end

  def item_gst_rate(item)
    # Try to get GST rate from product/variant HSN code, default to 3% or calculated
    if item.product_variant&.product&.hsn_code&.gst_rate.present?
      item.product_variant.product.hsn_code.gst_rate
    elsif item.respond_to?(:gst_rate) && item.gst_rate.present?
      item.gst_rate
    elsif @order.tax_breakdown.present? && @order.tax_breakdown["summary"].present?
      @order.tax_breakdown["summary"].first["rate"]
    else
      3  # Default GST rate for jewelry
    end
  end

  def company_gstin
    @store_setting.respond_to?(:gst_number) ? @store_setting.gst_number : nil
  end

  def vendor_gstin
    return nil unless @order.vendor.present?
    @order.vendor.respond_to?(:gst_number) ? @order.vendor.gst_number : nil
  end

  def gst_eligibility_notice
    if customer_eligible_for_gst_benefits?
      "Customer is eligible for GST input tax credit."
    else
      "Customer is not eligible for GST input tax credit (B2C transaction)."
    end
  end

  def customer_eligible_for_gst_benefits?
    # B2B eligibility: If customer has GSTIN or order is for business use
    # For now, all customers get GST invoice but B2B status depends on GST registration
    @order.tax_amount.to_f > 0 && vendor_gstin.present?
  end

  def amount_in_words(amount)
    # Simple implementation - in production, use a proper gem like 'to_words'
    rupees = amount.to_i
    paise = ((amount - rupees) * 100).round

    result = "Rs. #{rupees}"
    result += " and #{paise} paise" if paise > 0
    result += " only"
    result
  end

  # Helper method to truncate strings for PDF display
  def truncate_string(str, n)
    str.length > n ? "#{str[0..n-3]}..." : str
  end
end
