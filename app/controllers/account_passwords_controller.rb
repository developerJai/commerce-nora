class AccountPasswordsController < ApplicationController
  before_action :require_customer

  def edit
  end

  def update
    @customer = current_customer

    unless @customer.authenticate(params[:current_password])
      flash.now[:alert] = "Current password is incorrect"
      return render :edit, status: :unprocessable_entity
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = "New passwords do not match"
      return render :edit, status: :unprocessable_entity
    end

    if @customer.update(password: params[:password])
      redirect_to account_path, notice: "Password updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
