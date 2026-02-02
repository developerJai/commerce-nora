class AddressesController < ApplicationController
  before_action :require_customer
  before_action :set_address, only: [:show, :edit, :update, :destroy]

  def index
    @addresses = current_customer.addresses.default_first
  end

  def show
  end

  def new
    @address = current_customer.addresses.build
  end

  def create
    @address = current_customer.addresses.build(address_params)

    if @address.save
      redirect_to addresses_path, notice: "Address added successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @address.update(address_params)
      redirect_to addresses_path, notice: "Address updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @address.destroy
    redirect_to addresses_path, notice: "Address deleted"
  end

  private

  def set_address
    @address = current_customer.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(
      :address_type, :first_name, :last_name, :phone,
      :street_address, :apartment, :city, :state,
      :postal_code, :country, :is_default
    )
  end
end
