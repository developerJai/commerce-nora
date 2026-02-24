# frozen_string_literal: true

require "razorpay"

# Load Razorpay credentials from environment-specific credentials
# Development: config/credentials/development.yml.enc
# Production: config/credentials/production.yml.enc
# Test: config/credentials/test.yml.enc

creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
        Rails.application.credentials.dig(:razorpay)

if creds.present?
  Razorpay.setup(creds[:key_id], creds[:key_secret])

  # Log configuration (mask secret, show partial key)
  environment = creds[:key_id].to_s.start_with?("rzp_live_") ? "LIVE" : "TEST"
  Rails.logger.info "[Razorpay] Initialized in #{environment} mode"
  Rails.logger.info "[Razorpay] Webhook secret: #{creds[:key_secret].present? ? "configured ✓" : "not configured ⚠"}"
else
  Rails.logger.warn "[Razorpay] Credentials not configured - payment features disabled"
  Rails.logger.warn "[Razorpay] Run: rails razorpay:setup_credentials"
end
