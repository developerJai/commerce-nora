namespace :razorpay do
  desc "Setup Razorpay credentials (interactive)"
  task setup_credentials: :environment do
    require "io/console"

    puts "\n🔐 Razorpay Credentials Setup"
    puts "=" * 50

    # Get environment
    puts "\nSelect environment:"
    puts "1. Development (test mode - for localhost)"
    puts "2. Production (live mode - for real payments)"
    print "Choice (1/2): "
    env_choice = STDIN.gets.chomp

    environment = env_choice == "2" ? "production" : "development"
    key_prefix = env_choice == "2" ? "rzp_live_" : "rzp_test_"

    puts "\n📝 Enter your Razorpay #{environment.upcase} credentials:"
    puts "(Get these from https://dashboard.razorpay.com → API Keys)"
    puts

    print "Key ID (starts with #{key_prefix}): "
    key_id = STDIN.gets.chomp

    print "Key Secret: "
    key_secret = STDIN.noecho { gets }.chomp
    puts

    print "Webhook Secret (optional for dev, required for prod): "
    webhook_secret = STDIN.noecho { gets }.chomp
    puts

    # Validate key format
    unless key_id.start_with?(key_prefix)
      puts "\n⚠️  Warning: Key ID should start with #{key_prefix}"
      print "Continue anyway? (y/n): "
      confirm = STDIN.gets.chomp.downcase
      exit unless confirm == "y"
    end

    # Edit the correct credentials file
    puts "\n💾 Saving to credentials..."

    if environment == "production"
      # Production credentials
      creds_file = "config/credentials/production.yml.enc"

      # Check if production key exists
      unless File.exist?("config/credentials/production.key") || ENV["RAILS_MASTER_KEY"].present?
        puts "\n⚠️  Production master key not found!"
        puts "Creating new production credentials file..."
        puts "A new master key will be generated. SAVE THIS SECURELY!"
        puts

        # Generate new production credentials file
        system("EDITOR='cat' rails credentials:edit --environment production 2>/dev/null")
      end

      # Edit production credentials
      require "tmpdir"

      Dir.mktmpdir do |dir|
        tmp_file = File.join(dir, "credentials.yml")

        # Decrypt existing or create new
        begin
          if File.exist?(creds_file)
            master_key = ENV["RAILS_MASTER_KEY"] || File.read("config/credentials/production.key").strip
            encrypted_file = Rails::EncryptedFile.new(
              file_path: creds_file,
              key_path: "config/credentials/production.key",
              env_key: "RAILS_MASTER_KEY",
              raise_if_missing_key: true
            )
            existing_content = encrypted_file.read
            File.write(tmp_file, existing_content) if existing_content.present?
          end
        rescue => e
          puts "Note: Could not read existing credentials (#{e.message})"
        end

        # Read current content or start fresh
        content = File.exist?(tmp_file) ? File.read(tmp_file) : ""

        # Parse YAML if exists
        require "yaml"
        yaml = content.present? ? YAML.safe_load(content, aliases: true) || {} : {}
        yaml ||= {}

        # Add/update razorpay section
        yaml["razorpay"] = {
          "key_id" => key_id,
          "key_secret" => key_secret,
          "webhook_secret" => webhook_secret.presence
        }.compact

        # Write back
        File.write(tmp_file, yaml.to_yaml)

        # Re-encrypt
        system("cat #{tmp_file} | EDITOR='cat' rails credentials:edit --environment production 2>/dev/null")

        puts "✅ Production credentials saved!"
      end
    else
      # Development credentials
      system("rails credentials:edit --environment development") do
        puts <<~INSTRUCTIONS

          # Add these lines to the file:

          razorpay:
            key_id: #{key_id}
            key_secret: #{key_secret}
            webhook_secret: #{webhook_secret.presence || "your_webhook_secret"}

          # Then save and exit
        INSTRUCTIONS
      end
    end

    puts "\n📋 Next Steps:"
    puts "1. Test the configuration:"
    puts "   rails razorpay:test_config"
    puts
    puts "2. Set up webhook in Razorpay Dashboard:"
    puts "   URL: https://yourdomain.com/razorpay/webhook"
    puts "   Events: payment.captured, payment.failed, order.paid"
    puts
    puts "3. For production, save your master key:"
    puts "   - Store in password manager (1Password, etc.)"
    puts "   - Or set as ENV variable: export RAILS_MASTER_KEY=xxx"
    puts
  end

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
