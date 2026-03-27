class CreateOtpVerifications < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_verifications do |t|
      t.string :phone
      t.string :otp
      t.datetime :expires_at
      t.string :reset_token
      t.datetime :reset_sent_at
      t.integer :attempts

      t.timestamps
    end
  end
end
