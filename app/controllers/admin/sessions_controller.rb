module Admin
  class SessionsController < ApplicationController
    layout 'admin_auth'

    before_action :redirect_if_logged_in, only: [:new, :create]

    def new
    end

    def create
      unless valid_captcha?
        flash.now[:alert] = "Please complete the verification challenge"
        render :new, status: :unprocessable_entity
        return
      end

      admin = AdminUser.authenticate(params[:email], params[:password], role: 'admin')

      if admin && admin.active?
        session[:admin_id] = admin.id
        admin.update(last_login_at: Time.current)
        redirect_to admin_root_path, notice: "Welcome back, #{admin.name}!"
      else
        flash.now[:alert] = "Invalid email or password"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_id)
      session.delete(:acting_as_vendor_id)
      redirect_to admin_login_path, notice: "You have been logged out"
    end

    private

    def redirect_if_logged_in
      redirect_to admin_root_path if session[:admin_id] && AdminUser.exists?(session[:admin_id])
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
