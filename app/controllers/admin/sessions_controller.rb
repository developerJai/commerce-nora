module Admin
  class SessionsController < ApplicationController
    layout 'admin_auth'

    before_action :redirect_if_logged_in, only: [:new, :create]

    def new
    end

    def create
      admin = AdminUser.authenticate(params[:email], params[:password])

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
      redirect_to admin_login_path, notice: "You have been logged out"
    end

    private

    def redirect_if_logged_in
      redirect_to admin_root_path if session[:admin_id] && AdminUser.exists?(session[:admin_id])
    end
  end
end
