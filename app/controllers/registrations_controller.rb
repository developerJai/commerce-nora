class RegistrationsController < ApplicationController
  before_action :redirect_if_logged_in

  def new
    @customer = Customer.new
    @customer.phone = params[:phone] if params[:phone].present?
    @customer.email = params[:email] if params[:email].present?

    @country_code = params[:country_code] || "+91"
  end

  def send_otp
    # 🔹 Normalize inputs
    raw_phone   = params[:customer][:phone].to_s
    country_code = params[:customer][:country_code].presence || "+91"
    email       = params[:customer][:email].to_s.strip.downcase
    otp_type    = params[:type] || "sms"

    phone = raw_phone.gsub(/\s+/, "")

    # 🔹 Build full phone (+91xxxxxxxxxx)
    full_phone = phone.start_with?('+') ? phone : "#{country_code}#{phone}"

    email = nil if email.blank?

    # 🔴 Check if phone already exists
    if Customer.exists?(phone: full_phone)
      return respond_error("Phone number already registered. Please login.")
    end

    # 🔴 Check if email already exists
    if email.present? && Customer.exists?(email: email)
      return respond_error("Email already registered. Please login.")
    end

    # 🔐 Generate OTP
    otp = rand(100000..999999).to_s

    # 🧹 Remove old OTPs for this phone (optional but recommended)
    OtpVerification.where(phone: full_phone).delete_all

    # 💾 Save OTP
    OtpVerification.create!(
      phone: full_phone,
      otp: otp,
      expires_at: 5.minutes.from_now,
      attempts: 0
    )

    # 🧠 Store in session
    session[:signup_phone] = full_phone
    session[:signup_data]  = customer_params
    session[:otp_type]     = otp_type
    session[:otp_sent_at]  = Time.current.to_i

    # 📩 TODO: Send OTP via SMS / WhatsApp (integration here)
    Rails.logger.info "OTP for #{full_phone}: #{otp}"

    # 🚀 Redirect
    redirect_to signup_verify_path
  end

  def verify
    @phone = session[:signup_phone]
    @country_code = session[:country_code] || "+91"
    @otp_type = session[:otp_type] || "sms"

    if session[:otp_sent_at].present?
      elapsed = Time.current.to_i - session[:otp_sent_at].to_i
      @remaining_time = [120 - elapsed, 0].max
    else
      @remaining_time = 120
    end
  end
  
  def confirm_otp
    phone = session[:signup_phone].to_s.gsub(/\s+/, "")
    country_code = session[:country_code] || "+91"

    full_phone = phone
    if country_code.present? && !phone.start_with?('+')
      full_phone = "#{country_code}#{phone}"
    end

    record = OtpVerification.where(phone: full_phone).order(created_at: :desc).first

    # ❌ SESSION EXPIRED
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

    # ❌ OTP EXPIRED
    if record.expired?
      record.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "otp_error",
            partial: "shared/otp_error",
            locals: { message: "OTP expired. Please request a new OTP." }
          ), status: :unprocessable_entity   # 🔥 MUST
        end
        format.html do
          redirect_to signup_verify_path, alert: "OTP expired"
        end
      end
      return
    end

    # ❌ INVALID OTP
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
          ), status: :unprocessable_entity   # 🔥 MUST
        end
        format.html do
          redirect_to signup_verify_path, alert: "Invalid OTP"
        end
      end
      return
    end

    # ✅ SUCCESS CASE
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
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "otp_error",
            partial: "shared/otp_error",
            locals: { message: @customer.errors.full_messages.join(", ") }
          ), status: :unprocessable_entity   # 🔥 MUST
        end
        format.html do
          render :verify
        end
      end
    end
  end

  def resend_otp
    phone = session[:signup_phone]
    country_code = session[:country_code] || "+91"
  
    full_phone = phone
    if country_code.present? && !phone.start_with?('+')
      full_phone = "#{country_code}#{phone}"
    end

    record = OtpVerification.find_by(phone: full_phone)

    if record.nil?
      redirect_to signup_path, alert: "Session expired"
      return
    end

    otp = rand(100000..999999)

    record.update(
      otp: otp,
      attempts: 0,
      expires_at: 5.minutes.from_now
    )

    otp_type = params[:type] || session[:otp_type] || "sms"
    session[:otp_type] = otp_type

    session[:otp_sent_at] = Time.current.to_i

    notice_message =
    if otp_type == "whatsapp"
      "OTP has been sent to WhatsApp"
    elsif otp_type == "sms"
      "OTP has been sent to SMS"
    else
      "OTP resent successfully"
    end

    redirect_back fallback_location: signup_verify_path,
                  notice: notice_message
  end
  
  private

  def respond_error(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "signup_error",
          partial: "shared/error_message",
          locals: { message: message }
        )
      end

      format.html do
        redirect_to signup_path, alert: message
      end
    end
  end

  def customer_params
    data = params.require(:customer).permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :password,
      :password_confirmation
    )

    data[:email] = nil if data[:email].blank?
    data
  end

  def redirect_if_logged_in
    redirect_to root_path if customer_logged_in?
  end
end