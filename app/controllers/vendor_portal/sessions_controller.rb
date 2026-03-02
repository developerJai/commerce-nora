module VendorPortal
  class SessionsController < ApplicationController
    layout 'admin_auth'

    before_action :redirect_if_logged_in, only: [:new, :create]

    def new
      @portal = 'vendor'
    end

    def create
      unless valid_captcha?
        flash.now[:alert] = "Please complete the verification challenge"
        @portal = 'vendor'
        render :new, status: :unprocessable_entity
        return
      end

      admin_user = AdminUser.authenticate(params[:email], params[:password], role: 'vendor')

      if admin_user && admin_user.active?
        session[:admin_id] = admin_user.id
        admin_user.update(last_login_at: Time.current)
        redirect_to admin_root_path, notice: "Welcome back, #{admin_user.name}!"
      else
        flash.now[:alert] = "Invalid email or password"
        @portal = 'vendor'
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_id)
      session.delete(:acting_as_vendor_id)
      redirect_to vendor_login_path, notice: "You have been logged out"
    end

    private

    def redirect_if_logged_in
      if session[:admin_id] && AdminUser.where(role: 'vendor').exists?(session[:admin_id])
        redirect_to admin_root_path
      end
    end

    def valid_captcha?
      token = params[:captcha_token]
      return false if token.blank?
      
      parts = token.split('-')
      return false if parts.length != 2
      
      timestamp = parts[0].to_i
      current_time = (Time.current.to_f * 1000).to_i
      
      time_diff = current_time - timestamp
      time_diff >= 0 && time_diff < 300000
    end
  end
end
