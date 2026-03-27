class OtpVerification < ApplicationRecord
	validates :phone, presence: true
	validates :otp, presence: true

	def expired?
	   expires_at.present? && expires_at < Time.current
	end
end
