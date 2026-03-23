class OtpVerification < ApplicationRecord
  def expired?
    expires_at.present? && expires_at < Time.current
  end
end