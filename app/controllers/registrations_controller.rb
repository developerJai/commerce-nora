class RegistrationsController < ApplicationController
  before_action :redirect_if_logged_in

  def new
    @customer = Customer.new

    @customer.phone = params[:phone] if params[:phone].present?
    @customer.email = params[:email] if params[:email].present?

    @country_code = params[:country_code] || "+91"
  end

  def send_otp
    phone = params[:customer][:phone]

    otp = rand(100000..999999).to_s

    OtpVerification.create(
      phone: phone,
      otp: otp,
      expires_at: 5.minutes.from_now
    )

    session[:signup_phone] = phone
    session[:signup_data]  = customer_params

    Rails.logger.info "OTP for #{phone} is #{otp}"

    redirect_to signup_verify_path
  end

  def verify
    @phone = session[:signup_phone]
  end

  def confirm_otp

    phone = session[:signup_phone]

    record = OtpVerification.find_by(phone: phone)

    if record.nil?
      redirect_to signup_path, alert: "Session expired"
      return
    end

    if record.expired?
      flash[:alert] = "OTP expired. Please request a new OTP."
      redirect_to signup_verify_path
      return
    end

    if params[:otp].to_s == record.otp.to_s

    data = session[:signup_data].symbolize_keys

    if data[:first_name].present?
      names = data[:first_name].strip.split(" ")
      data[:first_name] = names.first
      data[:last_name]  = names[1..].join(" ")
      data[:last_name]  = "" if data[:last_name].blank?
    end

      @customer = Customer.new(data)

      if @customer.save

        session[:customer_id] = @customer.id

        if session[:cart_token]
          guest_cart = Cart.find_by(token: session[:cart_token])
          if guest_cart
            @customer.active_cart.merge_with!(guest_cart)
            session.delete(:cart_token)
          end
        end

        record.destroy

        session.delete(:signup_phone)
        session.delete(:signup_data)

        redirect_to root_path, notice: "Welcome to Noralooks!"

      else
        render :verify
      end

    else
      flash.now[:alert] = "Invalid OTP"
      render :verify
    end

  end

  def resend_otp
    phone = session[:signup_phone]

    otp = rand(100000..999999)

    record = OtpVerification.find_by(phone: phone)

    record.update(
      otp: otp,
      expires_at: 5.minutes.from_now
    )

    Rails.logger.info "Resent OTP #{otp}"

    redirect_to signup_verify_path, notice: "OTP sent again"

  end

  # def create
  #   @customer = Customer.new(customer_params)
  #   if @customer.save
  #     session[:customer_id] = @customer.id
  #     if session[:cart_token]
  #       guest_cart = Cart.find_by(token: session[:cart_token])
  #       if guest_cart
  #         @customer.active_cart.merge_with!(guest_cart)
  #         session.delete(:cart_token)
  #       end
  #     end
  #     redirect_to root_path, notice: "Welcome to Auracraft!"
  #   else
  #     render :new, status: :unprocessable_entity
  #   end
  # end

  private

  def customer_params
    params.require(:customer).permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :password,
      :password_confirmation
    )
  end

  def redirect_if_logged_in
    redirect_to root_path if customer_logged_in?
  end
end