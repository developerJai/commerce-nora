namespace :razorpay do

  desc "Test Razorpay configuration"
  task test_config: :environment do
    puts "\n🧪 Testing Razorpay Configuration"
    puts "=" * 50
    puts "Environment: #{Rails.env.upcase}"
    puts

    begin
      creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
        Rails.application.credentials.dig(:razorpay)

      key_id = creds[:key_id]
      key_secret = creds[:key_secret]
      webhook_secret = creds[:webhook_secret]

      if key_id.blank? || key_secret.blank?
        puts "\n❌ ERROR: Razorpay credentials not configured!"
        puts "\nTo fix this, run:"
        puts "   rails razorpay:setup_credentials"
        puts
        puts "Or manually edit:"
        if Rails.env.production?
          puts "   rails credentials:edit --environment production"
        else
          puts "   rails credentials:edit --environment development"
        end
        exit 1
      end

      puts "✅ Credentials found"
      puts "   Key ID: #{key_id[0..15]}..."

      # Detect environment from key
      is_live = key_id.start_with?("rzp_live_")
      is_test = key_id.start_with?("rzp_test_")

      if is_live
        puts "   Mode: 🔴 LIVE (Real money transactions)"
        if Rails.env.development?
          puts "\n⚠️  WARNING: Using LIVE keys in development!"
          puts "   Make sure you really want to do this."
        end
      elsif is_test
        puts "   Mode: 🧪 TEST (Sandbox mode)"
      else
        puts "   Mode: ⚠️  UNKNOWN (Key format not recognized)"
      end

      # Test API connection
      puts "\n🌐 Testing API connection..."

      begin
        # Try to fetch orders (lightweight test)
        test_orders = Razorpay::Order.all(count: 1)
        puts "✅ API connection successful!"
        puts "   Test orders fetch: #{test_orders.items.count} orders found"
      rescue Razorpay::Error => e
        puts "\n❌ API Error: #{e.message}"
        puts "   Check your key_id and key_secret are correct"
        exit 1
      end

      # Webhook secret check
      puts "\n📡 Webhook Configuration:"
      if webhook_secret.present?
        puts "✅ Webhook secret configured"
        puts "   Secret: #{webhook_secret[0..10]}..."
      else
        puts "⚠️  Webhook secret NOT configured"
        puts "   Webhook signature verification will be disabled"
        puts "   (This is OK for development, but REQUIRED for production)"
      end

      puts "\n" + "=" * 50
      puts "✅ All tests passed!"
      puts
      puts "🎯 Ready to accept payments!"
      puts

      if is_test
        puts "🧪 Test Cards:"
        puts "   Success: 5267 3181 8797 5449"
        puts "   Failure: 4111 1111 1111 1111"
        puts
      end

    rescue => e
      puts "\n❌ ERROR: #{e.message}"
      puts e.backtrace.first(3).join("\n")
      exit 1
    end
  end

  desc "Show current Razorpay configuration (safe)"
  task show_config: :environment do
    puts "\n📊 Razorpay Configuration"
    puts "=" * 50
    
    creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
        Rails.application.credentials.dig(:razorpay)

    key_id = creds[:key_id]
    key_secret = creds[:key_secret]
    webhook_secret = creds[:webhook_secret]

    puts "Environment: #{Rails.env.upcase}"
    puts

    if key_id.present?
      puts "Key ID: #{key_id[0..20]}..."
      puts "Type: #{key_id.start_with?("rzp_live_") ? "🔴 LIVE" : "🧪 TEST"}"
    else
      puts "Key ID: ❌ Not configured"
    end

    puts
    puts "Webhook Secret: #{webhook_secret.present? ? "✅ Configured" : "❌ Not configured"}"

    # Check credentials file location
    if Rails.env.production?
      file = "config/credentials/production.yml.enc"
    else
      file = "config/credentials/#{Rails.env}.yml.enc"
      file = "config/credentials.yml.enc" unless File.exist?(file)
    end

    puts "Credentials File: #{File.exist?(file) ? "✅ #{file}" : "❌ Not found"}"
    puts
  end
end
