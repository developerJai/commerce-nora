class SessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [:new, :create]

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
          )
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
      @remaining_time = [30 - elapsed, 0].max
    else
      @remaining_time = 30
    end
  end

  # SEND OTP
# SEND OTP
  def send_otp
    login = params[:login].to_s.strip
    country_code = params[:country_code]
    otp_type = params[:type] || "login"

    if login.include?("@")
      customer = Customer.find_by(email: login)

      unless customer
        redirect_to forgotpassword_path, alert: "Email not found"
        return
      end

      full_phone = customer.phone
    else
      full_phone = login.start_with?("+") ? login : "#{country_code}#{login}"
    end

    otp = rand(100000..999999)
    token = SecureRandom.uuid

    record = OtpVerification.find_or_initialize_by(phone: full_phone)

    record.update(
      otp: otp,
      expires_at: 2.minutes.from_now
    )

    # ✅ ADD THIS
    session[:otp_sent_at] = Time.current.to_i

    session[:otp_phone] = full_phone
    session[:otp_token] = token
    session[:otp_type] = otp_type
    session[:otp_sent_at] = Time.current.to_i

    if otp_type == "reset"
      redirect_to forgototp_path(token: token)
    else
      redirect_to otp_path(token: token)
    end
  end

  # RESEND OTP
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
      expires_at: 2.minutes.from_now
    )

    # ✅ RESET TIMER AGAIN
    session[:otp_sent_at] = Time.current.to_i

    Rails.logger.info "Resend OTP ===== #{otp}"

    redirect_back fallback_location: signin_path,
                  notice: "OTP resent successfully"
  end

  def verify_otp
    phone = session[:otp_phone]
    otp_type = session[:otp_type] # 👈 NEW (login / reset)

    record = OtpVerification.find_by(phone: phone)

    # ❌ Session missing
    if phone.blank? || record.nil?
      redirect_to signin_path, alert: "Session expired"
      return
    end

    # ⏱ Expired OTP
    if record.expired?
      record.destroy
      session.delete(:otp_phone)
      session.delete(:otp_token)
      session.delete(:otp_type)

      redirect_to signin_path, alert: "OTP expired. Please request a new OTP."
      return
    end

    # ✅ OTP MATCH
    if params[:otp].to_s == record.otp.to_s

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

      when "reset"
        customer = Customer.find_by(phone: phone) || Customer.find_by(email: phone)
        unless customer
          redirect_to signin_path, alert: "Account not found"
          return
        end

        # ✅ THIS IS THE MAIN FIX
        session[:reset_customer_id] = customer.id

        notice_msg = "OTP verified. Set new password"
        redirect_path = change_password_path

      else
        redirect_to signin_path, alert: "Invalid OTP type"
        return
      end

      # 🧹 cleanup
      record.destroy
      session.delete(:otp_phone)
      session.delete(:otp_token)
      session.delete(:otp_type)

      redirect_to redirect_path, notice: notice_msg

    else
      # ❌ WRONG OTP
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "otp_error",
            partial: "shared/otp_error",
            locals: { message: "Invalid OTP. Please check your code and try again." }
          )
        end

        format.html do
          flash.now[:alert] = "Invalid OTP"
          render :otp
        end
      end
    end
  end

  def forgot_password
    @login = params[:login]
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
      @remaining_time = [30 - elapsed, 0].max
    else
      @remaining_time = 30
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
      render :change_password and return
    end

    if @customer.update(password: params[:password],
                        password_confirmation: params[:password_confirmation])
    reset_session
    session[:customer_id] = @customer.id

      # ✅ cleanup
      session.delete(:reset_customer_id)

      redirect_to root_path, notice: "Password updated successfully"
    else
      flash.now[:alert] = @customer.errors.full_messages.join(", ")
      render :change_password
    end
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