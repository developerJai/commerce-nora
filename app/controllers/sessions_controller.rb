class SessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [:new, :signin, :create, :otp, :verify_otp, :forgot_password, :forgot_otp,:change_password]

  def new
    session[:return_to] = params[:return_to] || request.referer
  end

  def check_login
    @login = params[:login].to_s.strip
    @country_code = params[:country_code]

    phone = "#{@country_code}#{@login}"

    @customer = Customer.find_by(email: @login) ||
                Customer.find_by(phone: phone)

    respond_to do |format|
      if @customer
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "login_step",
            partial: "sessions/password_step",
            locals: { login: @login, country_code: @country_code }
          )
        end
      else
        @customer = Customer.new(phone: phone)

        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "login_step",
            partial: "sessions/signup",
            locals: { customer: @customer }
          )
        end
      end
    end
  end

  def create
    login = params[:login]
    password = params[:password]
    country_code = params[:country_code]
    phone = "#{country_code}#{login}"

    customer = Customer.find_by(email: params[:login]) || Customer.find_by(phone: phone)

    if customer&.authenticate(params[:password])
      session[:customer_id] = customer.id
      redirect_to root_path, notice: "Logged in successfully"
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "login_error",
            partial: "shared/error_message",
            locals: { message: "Incorrect password. Please try again." }
          ), status: :unprocessable_entity
        end

        format.html do
          flash.now[:alert] = "Incorrect password. Please try again."
          render :new
        end
      end
    end
  end

  def create_account
    @customer = Customer.new(customer_params)

    if @customer.save
      session[:customer_id] = @customer.id
      redirect_to root_path
    else
      render turbo_stream: turbo_stream.replace(
        "login_step",
        partial: "sessions/signup",
        locals: { customer: @customer }
      )
    end
  end

  def destroy
    session.delete(:customer_id)
    redirect_to root_path, notice: "Logged out"
  end

  def otp
    if params[:token] != session[:otp_token]
      redirect_to signin_path, alert: "Invalid session"
      return
    end

    phone = session[:otp_phone]

    @country_code = phone[0..2]
    @login = phone[3..]
    @otp_type = session[:otp_type]

    # ✅ TIMER LOGIC
    if session[:otp_sent_at]
      elapsed = Time.current.to_i - session[:otp_sent_at].to_i
      @remaining_time = [120 - elapsed, 0].max
    else
      @remaining_time = 120
    end
  end

  def send_otp
    login        = params[:login].to_s.strip
    country_code = params[:country_code].presence || "+91"
    otp_type     = params[:type] || "login"

    otp   = rand(100000..999999).to_s
    token = SecureRandom.uuid

    if login.include?("@")
      customer = Customer.find_by(email: login.downcase)

      unless customer
        redirect_to forgotpassword_path, alert: "Email not found" and return
      end

      full_phone = customer.phone

      OtpVerification.where(phone: full_phone).delete_all

      OtpVerification.create!(
        phone: full_phone,
        otp: otp,
        expires_at: 5.minutes.from_now,
        reset_token: (otp_type == "reset" ? token : nil),
        reset_sent_at: Time.current,
        attempts: 0
      )

      session[:otp_phone]   = full_phone
      session[:otp_token]   = token
      session[:otp_type]    = otp_type
      session[:otp_sent_at] = Time.current.to_i

      if otp_type == "reset"
        reset_link = "#{request.base_url}/password/request/email?token=#{token}&login=#{customer.email}"

        UserMailer.reset_password_email(customer, otp, reset_link).deliver_now

        redirect_to forgotpassword_path(token: token, login: customer.email),
                    notice: "OTP and reset link sent to your email"
      else
        redirect_to forgototp_path(token: token)
      end

    else
      phone = login.gsub(/\s+/, "")
      full_phone = phone.start_with?('+') ? phone : "#{country_code}#{phone}"

      OtpVerification.where(phone: full_phone).delete_all

      OtpVerification.create!(
        phone: full_phone,
        otp: otp,
        expires_at: 5.minutes.from_now,
        attempts: 0
      )

      Rails.logger.info "Send OTP to #{full_phone}: #{otp}"

      session[:otp_phone]   = full_phone
      session[:otp_token]   = token
      session[:otp_type]    = otp_type
      session[:otp_sent_at] = Time.current.to_i

      if otp_type == "reset"
        redirect_to forgototp_path(token: token),
                    notice: "OTP sent to your phone"
      else
        redirect_to otp_path(token: token)
      end
    end
  end

  def resend_otp
    phone = session[:otp_phone]

    record = OtpVerification.find_by(phone: phone)

    if record.nil?
      redirect_to signin_path, alert: "Session expired"
      return
    end

    otp = rand(100000..999999)

    record.update(
      otp: otp,
      expires_at: 5.minutes.from_now,
      attempts: 0
    )

    # ✅ RESET TIMER AGAIN
    session[:otp_sent_at] = Time.current.to_i

    Rails.logger.info "Resend OTP ===== #{otp}"

    redirect_back fallback_location: signin_path,
                  notice: "OTP resent successfully"
  end

  def verify_otp
    phone = session[:otp_phone]
    otp_type = session[:otp_type]

    record = OtpVerification.find_by(phone: phone) 
    if phone.blank? || record.nil?
      redirect_to signin_path, alert: "Session expired"
      return
    end
    if record.attempts.to_i >= 3
      session.delete(:otp_phone)
      session.delete(:otp_token)
      session.delete(:otp_type)

      redirect_to signin_path, alert: "Too many wrong OTP attempts. Please login again."
      return
    end
    if record.expired?
      record.update(reset_token: nil, attempts: 0)

      session.delete(:otp_phone)
      session.delete(:otp_token)
      session.delete(:otp_type)

      redirect_to signin_path, alert: "OTP expired. Please request a new OTP."
      return
    end

    if params[:otp].to_s == record.otp.to_s
      record.update(attempts: 0)

      case otp_type

      when "login"
        customer = Customer.find_by(phone: phone) || Customer.find_by(email: phone)
        if customer
          session[:customer_id] = customer.id
          notice_msg = "Logged in successfully"
          redirect_path = root_path
        else
          redirect_to signin_path, alert: "Account not found"
          return
        end

      when "reset", "reset_otp"
        customer = Customer.find_by(phone: phone) || Customer.find_by(email: phone)
        unless customer
          redirect_to signin_path, alert: "Account not found"
          return
        end

        session[:reset_customer_id] = customer.id
        notice_msg = "OTP verified. Set new password"
        redirect_path = change_password_path

      else
        redirect_to signin_path, alert: "Invalid OTP type"
        return
      end
      record.update(reset_token: nil)

      session.delete(:otp_phone)
      session.delete(:otp_token)
      session.delete(:otp_type)

      redirect_to redirect_path, notice: notice_msg

    else
      record.increment!(:attempts)

      remaining = 3 - record.attempts

      if record.attempts >= 3
        session.delete(:otp_phone)
        session.delete(:otp_token)
        session.delete(:otp_type)

        redirect_to signin_path, alert: "Too many wrong OTP attempts. Please login again."
        return
      end

      message = "Invalid OTP. #{remaining} attempts left."

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "otp_error",
            partial: "shared/otp_error",
            locals: { message: message }
          ), status: :unprocessable_entity
        end

        format.html do
          flash.now[:alert] = message
          render :otp
        end
      end
    end
  end

  def forgot_password
    @login = params[:login]
    @is_phone = @login.match?(/\A\d{10,15}\z/)
    @country_code = params[:country_code]
  end

  def forgot_otp
    if params[:token] != session[:otp_token]
      redirect_to signin_path, alert: "Invalid session"
      return
    end

    phone = session[:otp_phone]

    @country_code = phone[0..2]
    @login = phone[3..]
    @otp_type = session[:otp_type]

    # ✅ SAME TIMER
    if session[:otp_sent_at]
      elapsed = Time.current.to_i - session[:otp_sent_at].to_i
      @remaining_time = [120 - elapsed, 0].max
    else
      @remaining_time = 120
    end
  end

  def change_password
    unless session[:reset_customer_id]
      redirect_to forgotpassword_path, alert: "Unauthorized access"
    end
  end

  def password_update
    @customer = Customer.find_by(id: session[:reset_customer_id])

    unless @customer
      redirect_to forgotpassword_path, alert: "Session expired"
      return
    end

    if params[:password].blank? || params[:password_confirmation].blank?
      flash.now[:alert] = "Password fields cannot be blank"
      render :change_password and return
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = "Passwords do not match"
      render :change_password, status: :unprocessable_entity and return
    end

    if @customer.update(password: params[:password],
                        password_confirmation: params[:password_confirmation])

      reset_session
      session[:customer_id] = @customer.id

      redirect_to root_path, notice: "Password updated successfully ✅"

    else
      # 🔥 DEBUG LINE
      Rails.logger.info "ERRORS ===== #{@customer.errors.full_messages}"

      flash.now[:alert] = @customer.errors.full_messages.join(", ")
      render :change_password
    end
  end

  def password_request_email
    token = params[:token]

    record = OtpVerification.find_by(reset_token: token)

    if record.nil? || record.reset_sent_at < 10.minutes.ago
      redirect_to signin_path, alert: "Link expired"
      return
    end

    customer = Customer.find_by(phone: record.phone)

    if customer.nil?
      redirect_to signin_path, alert: "User not found"
      return
    end

    session[:otp_phone] = record.phone
    session[:otp_token] = token
    session[:otp_type] = "reset"

    @login = customer.email
    @country_code = "+91"
    @remaining_time = (record.expires_at - Time.current).to_i
  end

  private


  def password_params
    params.require(:customer).permit(:password, :password_confirmation)
  end

  def customer_params
    params.require(:customer).permit(:name, :email, :phone, :password)
  end

  def redirect_if_logged_in
    redirect_to root_path if customer_logged_in?
  end
end