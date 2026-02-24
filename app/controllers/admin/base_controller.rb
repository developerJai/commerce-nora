module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_admin

    helper_method :current_admin, :current_vendor, :admin_role?, :vendor_role?, :vendor_context?, :current_vendor_user?

    private

    def current_admin
      @current_admin ||= AdminUser.find_by(id: session[:admin_id]) if session[:admin_id]
    end

    # Returns the active vendor context (either the vendor's own or admin impersonation)
    def current_vendor
      @current_vendor ||= if admin_role? && session[:acting_as_vendor_id]
        Vendor.find_by(id: session[:acting_as_vendor_id])
      elsif vendor_role?
        current_admin&.vendor
      end
    end

    def admin_role?
      current_admin&.admin?
    end

    def vendor_role?
      current_admin&.vendor?
    end

    # True when data should be scoped to a vendor (vendor logged in OR admin impersonating)
    def vendor_context?
      current_vendor.present?
    end

    # True when a vendor is accessing (either direct login or admin impersonating)
    def current_vendor_user?
      current_vendor.present?
    end

    def require_admin
      unless current_admin
        flash[:alert] = "Please login to access admin area"
        redirect_to admin_login_path
      end
    end

    # Gate for admin-only controllers (vendors cannot access)
    def require_admin_role!
      unless admin_role?
        redirect_to admin_root_path, alert: "Access denied"
      end
    end

    def admin_logged_in?
      current_admin.present?
    end

    # Scope helper: returns base scope filtered to current vendor if in vendor context
    def vendor_scoped(scope)
      vendor_context? ? scope.where(vendor_id: current_vendor.id) : scope
    end
  end
end
