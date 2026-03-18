class CreateOtpVerifications < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_verifications do |t|
      t.string :phone
      t.string :otp
      t.datetime :expires_at

      t.timestamps
    end
  end
end
