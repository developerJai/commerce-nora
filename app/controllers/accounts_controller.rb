class AccountsController < ApplicationController
  before_action :require_customer

  def show
    @customer = current_customer
    @recent_orders = current_customer.orders.placed.recent.limit(5)
  end

  def edit
    @customer = current_customer
  end

  def update
    @customer = current_customer

    if @customer.update(account_params)
      redirect_to account_path, notice: "Account updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:customer).permit(:first_name, :last_name, :email, :phone)
  end
end
