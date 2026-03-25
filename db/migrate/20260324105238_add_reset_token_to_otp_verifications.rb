class AddResetTokenToOtpVerifications < ActiveRecord::Migration[8.1]
  def change
    add_column :otp_verifications, :reset_token, :string
    add_column :otp_verifications, :reset_sent_at, :datetime
  end
end
