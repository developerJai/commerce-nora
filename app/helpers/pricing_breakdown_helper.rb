module PricingBreakdownHelper
  # Renders a modal/popup for detailed pricing breakdown
  def pricing_breakdown_trigger(label = "View Breakdown", classes = nil)
    default_classes = "text-rose-700 hover:text-rose-900 text-sm font-medium underline cursor-pointer"

    content_tag :span,
                class: classes || default_classes,
                data: {
                  controller: "pricing-breakdown",
                  action: "click->pricing-breakdown#toggle"
                } do
      label
    end
  end

  def pricing_breakdown_modal(order, id_suffix = "")
    modal_id = "pricing-breakdown-modal-#{order.id}-#{id_suffix}"

    content_tag :div,
                id: modal_id,
                class: "hidden fixed inset-0 bg-black bg-opacity-50 z-50 overflow-y-auto",
                data: {
                  controller: "pricing-breakdown",
                  "pricing-breakdown-target": "modal"
                } do
      content_tag :div, class: "flex items-center justify-center min-h-screen p-4" do
        content_tag :div, class: "bg-white rounded-2xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto" do
          concat pricing_breakdown_header(order)
          concat pricing_breakdown_content(order)
        end
      end
    end
  end

  private

  def pricing_breakdown_header(order)
    content_tag :div, class: "sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between rounded-t-2xl" do
      concat content_tag(:h3, "Detailed Pricing Breakdown", class: "text-lg font-semibold text-gray-900")
      concat content_tag(:button,
                        class: "text-gray-400 hover:text-gray-600",
                        data: { action: "click->pricing-breakdown#close" }) do
        content_tag(:svg, "", class: "w-6 h-6", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M6 18L18 6M6 6l12 12")
        end
      end
    end
  end

  def pricing_breakdown_content(order)
    content_tag :div, class: "p-6 space-y-6" do
      content = ""

      # Subtotal Section
      content << pricing_section("Order Summary", [
        { label: "Subtotal", value: format_price(order.subtotal), bold: false },
        order.discount_amount.to_f > 0 ? { label: "Discount", value: "-#{format_price(order.discount_amount)}", color: "text-emerald-600" } : nil,
        { label: "Shipping", value: order.shipping_amount.to_f > 0 ? format_price(order.shipping_amount) : "FREE", color: order.shipping_amount.to_f > 0 ? nil : "text-emerald-600" }
      ].compact)

      # Tax Section
      tax_data = order.tax_breakdown_display
      if tax_data.present? && tax_data["summary"].present?
        tax_items = tax_data["summary"].map do |tax|
          {
            label: "GST @ #{tax['rate']}% (#{tax['item_count']} items)",
            value: format_price(tax["total_tax"]),
            sublabel: "Taxable: #{format_price(tax['total_taxable'])}"
          }
        end
        content << pricing_section("Tax Details (IGST/CGST+SGST)", tax_items, "bg-blue-50 border-blue-200")
      end

      # Total Section
      content << content_tag(:div, class: "border-t-2 border-gray-200 pt-4 mt-4") do
        content_tag(:div, class: "flex justify-between items-center") do
          concat content_tag(:span, "Total Amount Paid", class: "text-lg font-semibold text-gray-900")
          concat content_tag(:span, format_price(order.total_amount), class: "text-2xl font-bold text-gray-900")
        end
      end

      # Payment Method
      payment_method_text = case order.payment_method
      when "razorpay"
                             "Paid via Online Payment (Razorpay)"
      when "cod"
                             "Cash on Delivery - Pay when you receive"
      else
                             order.payment_method&.titleize
      end

      content << content_tag(:div, class: "mt-4 p-3 bg-gray-50 rounded-lg text-center") do
        content_tag(:p, payment_method_text, class: "text-sm text-gray-600")
      end

      content.html_safe
    end
  end

  def pricing_section(title, items, bg_class = nil)
    bg_class ||= "bg-gray-50"

    content_tag :div, class: "#{bg_class} border rounded-xl p-4" do
      concat content_tag(:h4, title, class: "text-sm font-semibold text-gray-700 mb-3")

      items.each do |item|
        next if item.nil?

        row_class = "flex justify-between items-center py-2 #{item == items.first ? '' : 'border-t border-gray-200'}"

        concat content_tag(:div, class: row_class) do
          label_class = "text-sm #{item[:bold] ? 'font-medium' : 'text-gray-600'}"
          value_class = "text-sm font-medium #{item[:color] || 'text-gray-900'}"

          label_content = item[:sublabel] ?
            content_tag(:div) do
              concat content_tag(:span, item[:label], class: label_class)
              concat content_tag(:span, " (#{item[:sublabel]})", class: "text-xs text-gray-500 block")
            end :
            content_tag(:span, item[:label], class: label_class)

          concat label_content
          concat content_tag(:span, item[:value], class: value_class)
        end
      end
    end
  end
end
