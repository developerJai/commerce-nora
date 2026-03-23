class RegistrationsController < ApplicationController
  before_action :redirect_if_logged_in

  def new
    @customer = Customer.new
    @customer.phone = params[:phone] if params[:phone].present?
    @customer.email = params[:email] if params[:email].present?

    @country_code = params[:country_code] || "+91"
  end

  def send_otp
    phone = params[:customer][:phone].to_s.gsub(/\s+/, "")
    country_code = params[:customer][:country_code] || "+91"
    email = params[:customer][:email].to_s.strip.downcase
    otp_type = params[:type] || "sms"

    email = nil if email.blank?

    full_phone = "#{country_code}#{phone}"

    Rails.logger.debug "FULL PHONE: #{full_phone}"

    # ❌ PHONE EXISTS
    if Customer.exists?(phone: full_phone)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "signup_error",
            partial: "shared/error_message",
            locals: { message: "Phone number already registered. Please login." }
          )
        end
        format.html do
          redirect_to signup_path, alert: "Phone number already registered."
        end
      end
      return
    end

    # ❌ EMAIL EXISTS
    if email.present? && Customer.exists?(email: email)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "signup_error",
            partial: "shared/error_message",
            locals: { message: "Email already registered. Please login." }
          )
        end
        format.html do
          redirect_to signup_path, alert: "Email already registered."
        end
      end
      return
    end

    # ✅ CREATE OTP
    otp = rand(100000..999999).to_s

    OtpVerification.create!(
      phone: full_phone,
      otp: otp,
      expires_at: 5.minutes.from_now
    )

    # ✅ SESSION STORE
    session[:signup_phone] = phone
    session[:country_code] = country_code
    session[:signup_data]  = customer_params
    session[:otp_type]     = otp_type
    session[:otp_sent_at]  = Time.current.to_i

    redirect_to signup_verify_path
  end

  def verify
    @phone = session[:signup_phone]
    @country_code = session[:country_code] || "+91"
    @otp_type = session[:otp_type] || "sms"

    if session[:otp_sent_at].present?
      elapsed = Time.current.to_i - session[:otp_sent_at].to_i
      @remaining_time = [30 - elapsed, 0].max
    else
      @remaining_time = 30
    end
  end
  
  def confirm_otp
    phone = session[:signup_phone].to_s.gsub(/\s+/, "")
    country_code = session[:country_code] || "+91"
    full_phone = "#{country_code}#{phone}"

    Rails.logger.debug "PHONE: #{full_phone}"

    record = OtpVerification.where(phone: full_phone).order(created_at: :desc).first

    if record.nil?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "otp_error",
            partial: "shared/otp_error",
            locals: { message: "Session expired. Please try again." }
          )
        end
        format.html do
          redirect_to signup_path, alert: "Session expired"
        end
      end
      return
    end

    if record.expired?
      record.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "otp_error",
            partial: "shared/otp_error",
            locals: { message: "OTP expired. Please request a new OTP." }
          )
        end
        format.html do
          redirect_to signup_verify_path, alert: "OTP expired"
        end
      end
      return
    end

    unless ActiveSupport::SecurityUtils.secure_compare(
      params[:otp].to_s,
      record.otp.to_s
    )
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "otp_error",
            partial: "shared/otp_error",
            locals: { message: "Invalid OTP. Please try again." }
          )
        end
        format.html do
          redirect_to signup_verify_path, alert: "Invalid OTP"
        end
      end
      return
    end

    data = session[:signup_data]&.symbolize_keys || {}
    data[:phone] = full_phone

    if data[:first_name].present?
      names = data[:first_name].strip.split(" ")
      data[:first_name] = names.first
      data[:last_name]  = names[1..].join(" ").presence || ""
    end

    @customer = Customer.new(data)

    if @customer.save
      session[:customer_id] = @customer.id

      record.destroy
      session.delete(:signup_phone)
      session.delete(:signup_data)
      session.delete(:country_code)

      respond_to do |format|
        format.html do
          redirect_to root_path, notice: "Welcome!"
        end
      end
    else
      Rails.logger.debug @customer.errors.full_messages

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "otp_error",
            partial: "shared/otp_error",
            locals: { message: @customer.errors.full_messages.join(", ") }
          )
        end
        format.html do
          render :verify
        end
      end
    end
  end

  def resend_otp
    phone = session[:signup_phone]

    record = OtpVerification.find_by(phone: phone)

    if record.nil?
      redirect_to signin_path, alert: "Session expired"
      return
    end

    otp = rand(100000..999999)

    record.update(
      otp: otp,
      expires_at: 5.minutes.from_now
    )

    # ✅ UPDATE TYPE (MAIN FIX)
    session[:otp_type] = params[:type] if params[:type].present?

    # ✅ RESET TIMER
    session[:otp_sent_at] = Time.current.to_i

    redirect_back fallback_location: signup_verify_path,
                  notice: "OTP resent successfully"
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
    data = params.require(:customer).permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :password,
      :password_confirmation
    )

    # ✅ blank email → nil
    data[:email] = nil if data[:email].blank?
    data
  end

  def redirect_if_logged_in
    redirect_to root_path if customer_logged_in?
  end
end