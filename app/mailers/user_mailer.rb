class UserMailer < ApplicationMailer
  def reset_password_email(customer, otp, reset_link)
    @customer = customer
    @otp = otp
    @reset_link = reset_link
    @time = Time.current

    mail(to: @customer.email, subject: "Reset your password")
  end
end