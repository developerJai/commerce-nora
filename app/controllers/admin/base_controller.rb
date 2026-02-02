module Admin
  class BaseController < ApplicationController
    layout 'admin'

    before_action :require_admin

    helper_method :current_admin

    private

    def current_admin
      @current_admin ||= AdminUser.find_by(id: session[:admin_id]) if session[:admin_id]
    end

    def require_admin
      unless current_admin
        flash[:alert] = "Please login to access admin area"
        redirect_to admin_login_path
      end
    end

    def admin_logged_in?
      current_admin.present?
    end
  end
end
