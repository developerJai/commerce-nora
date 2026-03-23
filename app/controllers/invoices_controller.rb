# frozen_string_literal: true

# Unified Invoice Controller
# Handles invoice downloads for all user types (customers, vendors, admins)
# with role-based access control
#
# Access Control:
# - Customers: Can only see their own order invoices
# - Vendors: Can only see invoices for orders where they are the vendor
# - Admins: Can see any invoice (with optional vendor view)
#
# Endpoints:
# - GET /invoices/:order_number - Customer invoice view
# - GET /invoices/:order_number?view_as_vendor=true - Vendor view (for admins)
#
class InvoicesController < ApplicationController
  before_action :authenticate_any_user!
  before_action :set_order
  before_action :authorize_invoice_access!

  # GET /invoices/:order_number
  # Unified endpoint for all user types to download invoices
  def show
    @order_items = @order.order_items.includes(:product_variant)

    # Determine invoice type based on current user role
    invoice_type = determine_invoice_type

    pdf = GstInvoiceGenerator.generate(@order, @order_items, type: invoice_type)

    filename = case invoice_type
    when :vendor then "Vendor_Invoice_#{@order.order_number}.pdf"
    when :admin then "Invoice_#{@order.order_number}.pdf"
    else "GST_Invoice_#{@order.order_number}.pdf"
    end

    send_data pdf.render,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def authenticate_any_user!
    # Check if any type of user is logged in
    unless customer_logged_in? || admin_present? || vendor_from_admin_present?
      redirect_to root_path, alert: "Please sign in to view invoices."
    end
  end

  def set_order
    @order = Order.find_by!(order_number: params[:order_number])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Order not found."
  end

  def authorize_invoice_access!
    # Admin can see any invoice
    return if admin_present?

    # Customer can only see their own orders
    if customer_logged_in?
      unless @order.customer_id == current_customer.id
        redirect_to orders_path, alert: "You don't have access to this invoice."
      end
      return
    end

    # Vendor (logged in via admin) can only see their orders
    if vendor_from_admin_present?
      vendor = current_vendor_from_admin
      unless vendor && @order.vendor_id == vendor.id
        redirect_to admin_root_path, alert: "You don't have access to this invoice."
      end
      return
    end

    # If none of the above, deny access
    redirect_to root_path, alert: "Access denied."
  end

  def determine_invoice_type
    if admin_present?
      # Admin can request vendor view if view_as_vendor param is present
      if params[:view_as_vendor].present? && @order.vendor.present?
        :vendor
      else
        :admin
      end
    elsif vendor_from_admin_present?
      :vendor
    else
      :customer
    end
  end

  # Check if admin is logged in (via admin namespace)
  def admin_present?
    session[:admin_id].present? && AdminUser.exists?(session[:admin_id])
  end

  # Check if vendor is accessing via admin impersonation
  def vendor_from_admin_present?
    return false unless session[:admin_id].present?
    admin_user = AdminUser.find_by(id: session[:admin_id])
    return false unless admin_user&.vendor?

    # Vendor is either acting as themselves or being impersonated by admin
    admin_user.vendor.present? || session[:acting_as_vendor_id].present?
  end

  # Get vendor when accessed via admin namespace
  def current_vendor_from_admin
    return nil unless session[:admin_id].present?

    # If admin is impersonating a vendor
    if session[:acting_as_vendor_id].present?
      Vendor.find_by(id: session[:acting_as_vendor_id])
    else
      # If vendor admin is logged in directly
      admin_user = AdminUser.find_by(id: session[:admin_id])
      admin_user&.vendor
    end
  end
end
