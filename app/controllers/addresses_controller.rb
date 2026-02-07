class AddressesController < ApplicationController
  before_action :require_customer
  before_action :set_address, only: [:show, :edit, :update, :destroy]

  def index
    @address_type = params[:address_type].to_s
    @address_type = 'shipping' unless Address::ADDRESS_TYPES.include?(@address_type)

    @addresses = current_customer.addresses.where(address_type: @address_type).default_first
  end

  def show
  end

  def new
    @address = current_customer.addresses.build
    requested_type = params[:address_type].to_s
    @address.address_type = requested_type if Address::ADDRESS_TYPES.include?(requested_type)
  end

  def create
    @address = current_customer.addresses.build(address_params)

    if @address.save
      redirect_to addresses_path(address_type: @address.address_type), notice: "Address added successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @address.update(address_params)
      redirect_to addresses_path(address_type: @address.address_type), notice: "Address updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    address_type = @address.address_type
    @address.destroy
    redirect_to addresses_path(address_type: address_type), notice: "Address deleted"
  end

  private

  def set_address
    @address = current_customer.addresses.find_by!(token: params[:token])
  end

  def address_params
    params.require(:address).permit(
      :address_type, :first_name, :last_name, :phone,
      :street_address, :apartment, :city, :state,
      :postal_code, :country, :is_default
    )
  end
end
