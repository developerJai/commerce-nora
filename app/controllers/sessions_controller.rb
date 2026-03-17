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
    customer = Customer.find_by(email: login) || Customer.find_by(phone: phone)
    if customer&.authenticate(password)
      session[:customer_id] = customer.id
      redirect_to root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid password"

      render turbo_stream: turbo_stream.replace(
        "login_step",
        partial: "sessions/password_step",
        locals: { login: login, country_code: country_code }
      )
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
      redirect_to login_path, alert: "Invalid session"
      return
    end
    phone = session[:otp_phone]
    @country_code = phone[0..2]
    @login = phone[3..]
    @otp_type = session[:otp_type]
  end

  def send_otp
    phone = params[:login]
    country_code = params[:country_code]
    otp_type = params[:type] || "sms"
    full_phone = "#{country_code}#{phone}"
    otp = rand(100000..999999)
    token = SecureRandom.uuid
    session[:otp] = otp
    session[:otp_phone] = full_phone
    session[:otp_token] = token
    session[:otp_type] = otp_type
    Rails.logger.info "OTP ===== #{otp}"
    if otp_type == "whatsapp"
      # WhatsappService.send(full_phone, otp)
    else
      # SmsService.send(full_phone, otp)
    end

    redirect_to otp_path(token: token)
  end

  def resend_otp
    otp = rand(100000..999999)

    session[:otp] = otp

    phone = session[:otp_phone]

    Rails.logger.info "Resend OTP ===== #{otp}"

    redirect_back fallback_location: login_path,
                  notice: "OTP resent successfully"
  end

  def verify_otp
    entered_otp = params[:otp]
    if entered_otp.to_s == session[:otp].to_s
      customer = Customer.find_by(phone: session[:otp_phone])
      session[:customer_id] = customer.id if customer
      session.delete(:otp)
      session.delete(:otp_phone)
      session.delete(:otp_token)
      redirect_to root_path, notice: "Logged in successfully"

    else
      flash.now[:alert] = "Invalid OTP"
      render :otp
    end
  end

  private

  def customer_params
    params.require(:customer).permit(:name, :email, :phone, :password)
  end

  def redirect_if_logged_in
    redirect_to root_path if customer_logged_in?
  end
end