class AddressesController < ApplicationController
  before_action :require_customer
  before_action :set_address, only: [:show, :edit, :update, :destroy]

  def index
    @addresses = current_customer.addresses.default_first
  end

  def show
  end

  def new
    @address = current_customer.addresses.build(country: 'India')
    @redirect_to = params[:redirect_to]
  end

  def create
    @address = current_customer.addresses.build(address_params)
    @redirect_to = params[:address][:redirect_to]

    if @address.save
      # Set as selected address for checkout if coming from checkout
      if @redirect_to == 'checkout'
        session[:checkout_address_id] = @address.id
        redirect_to checkout_path, notice: "Address added successfully"
      else
        redirect_to addresses_path, notice: "Address added successfully"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @redirect_to = params[:redirect_to]
  end

  def update
    @redirect_to = params[:address][:redirect_to]
    
    if @address.update(address_params)
      if @redirect_to == 'checkout'
        session[:checkout_address_id] = @address.id
        redirect_to checkout_path, notice: "Address updated successfully"
      else
        redirect_to addresses_path, notice: "Address updated successfully"
      end
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
    @address = current_customer.addresses.find_by!(token: params[:token])
  end

  def address_params
    params.require(:address).permit(
      :first_name, :last_name, :country_code, :phone,
      :street_address, :apartment, :city, :state,
      :postal_code, :country, :is_default
    )
  end
end
