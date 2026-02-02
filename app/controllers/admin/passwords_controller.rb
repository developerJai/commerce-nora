module Admin
  class PasswordsController < BaseController
    def edit
      @admin = current_admin
    end

    def update
      @admin = current_admin

      unless @admin.authenticate(params[:current_password])
        flash.now[:alert] = "Current password is incorrect"
        return render :edit, status: :unprocessable_entity
      end

      if params[:password] != params[:password_confirmation]
        flash.now[:alert] = "New passwords do not match"
        return render :edit, status: :unprocessable_entity
      end

      if @admin.update(password: params[:password])
        redirect_to admin_settings_path, notice: "Password updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
