# Rails Credentials Setup for Razorpay (Multi-Environment)

## Recommended Approach: Environment-Specific Credentials

Rails 6+ supports separate credential files per environment. This is the cleanest and most secure approach.

### Structure:

```
config/
├── credentials.yml.enc              # Default (development/test if others don't exist)
├── credentials/
│   ├── development.yml.enc          # Development only
│   ├── production.yml.enc           # Production only
│   └── test.yml.enc                 # Test environment
└── master.key                       # Master key (gitignored)
```

## Setup Instructions

### Step 1: Create Development Credentials

For **development/test mode** (Razorpay test keys):

```bash
# Creates config/credentials/development.yml.enc
rails credentials:edit --environment development
```

Add this content:

```yaml
# Razorpay TEST credentials (Development & Test)
razorpay:
  key_id: rzp_test_xxxxxxxxxxxxx        # Your test key ID
  key_secret: xxxxxxxxxxxxxxxxxxxx      # Your test key secret
  webhook_secret: whsec_test_xxxxxxxxx  # Test webhook secret (optional for dev)

# Other development credentials
secret_key_base: xxxxxxxxxxxxxxxxxxxx
```

### Step 2: Create Production Credentials

For **production** (Razorpay live keys):

```bash
# Creates config/credentials/production.yml.enc
rails credentials:edit --environment production
```

Add this content:

```yaml
# Razorpay LIVE credentials (Production only)
razorpay:
  key_id: rzp_live_xxxxxxxxxxxxx        # Your live key ID
  key_secret: xxxxxxxxxxxxxxxxxxxx      # Your live key secret
  webhook_secret: whsec_live_xxxxxxxxx  # Production webhook secret (REQUIRED)

# Other production credentials
secret_key_base: xxxxxxxxxxxxxxxxxxxx
```

### Step 3: Handle Master Keys

Each environment has its own master key:

```
config/master.key                    # Default master key
config/credentials/development.key # Development master key
config/credentials/production.key  # Production master key
```

**Important:**
- Never commit `.key` files to git
- Store production master key securely (ENV variable or password manager)
- For production deployment, set: `RAILS_MASTER_KEY=your_production_key`

### Step 4: Update Initializer

The initializer already handles this automatically! Rails loads the correct credentials based on `Rails.env`.

```ruby
# config/initializers/razorpay.rb

require 'razorpay'

key_id = Rails.application.credentials.dig(:razorpay, :key_id)
key_secret = Rails.application.credentials.dig(:razorpay, :key_secret)

if key_id.present? && key_secret.present?
  Razorpay.setup(key_id, key_secret)
  Rails.logger.info "[Razorpay] Initialized with key: #{key_id[0..10]}..."
else
  Rails.logger.warn "[Razorpay] Credentials not configured"
end
```

## How It Works

### Development Environment

```bash
rails server
# or
rails console

# Loads from: config/credentials/development.yml.enc
# Uses test keys: rzp_test_xxxxxxxxxxxxx
```

### Production Environment

```bash
RAILS_ENV=production rails server
# or on server with: RAILS_MASTER_KEY=xxx rails server

# Loads from: config/credentials/production.yml.enc
# Uses live keys: rzp_live_xxxxxxxxxxxxx
```

### Testing Environment

```bash
rails test

# Loads from: config/credentials/test.yml.enc
# Or falls back to: config/credentials/development.yml.enc
```

## Alternative: Single File with Environment Sections

If you prefer a single credentials file with sections:

```bash
rails credentials:edit
```

Add:

```yaml
development:
  razorpay:
    key_id: rzp_test_xxxxxxxxxxxxx
    key_secret: xxxxxxxxxxxxxxxxxxxx
    webhook_secret: whsec_test_xxxxxxx

production:
  razorpay:
    key_id: rzp_live_xxxxxxxxxxxxx
    key_secret: xxxxxxxxxxxxxxxxxxxx
    webhook_secret: whsec_live_xxxxxxx

test:
  razorpay:
    key_id: rzp_test_xxxxxxxxxxxxx
    key_secret: xxxxxxxxxxxxxxxxxxxx
    webhook_secret: whsec_test_xxxxxxx

secret_key_base: xxxxxxxxxxxxxx
```

Then update the initializer:

```ruby
# config/initializers/razorpay.rb
require 'razorpay'

creds = Rails.application.credentials[Rails.env.to_sym]&.dig(:razorpay) ||
        Rails.application.credentials.dig(:razorpay)

if creds.present?
  Razorpay.setup(creds[:key_id], creds[:key_secret])
end
```

**⚠️ Not recommended** - Environment-specific files are cleaner and safer.

## Quick Setup Script

I've created an interactive setup task:

```bash
# Interactive setup (creates files for you)
rails razorpay:setup_credentials

# Verify configuration
rails razorpay:test_config
```

This will:
1. Ask for environment (development/production)
2. Ask for your Razorpay credentials
3. Save them to the correct credentials file
4. Verify the configuration

## Security Best Practices

### 1. Never Commit Keys

Add to `.gitignore`:

```
/config/master.key
/config/credentials/*.key
```

### 2. Production Deployment

**Option A: Environment Variable (Recommended)**

On your production server:

```bash
# Set the master key as environment variable
export RAILS_MASTER_KEY=xxxxxxxxxxxxxxxxxxxx

# Rails will use this instead of config/credentials/production.key
```

**Option B: Key File**

```bash
# On server, create the key file
echo "xxxxxxxxxxxxxxxxxxxx" > config/credentials/production.key

# Ensure it's secure
chmod 600 config/credentials/production.key
```

### 3. Backup Keys

Store master keys securely:
- 1Password / LastPass
- AWS Secrets Manager
- HashiCorp Vault
- Physical secure location

### 4. Rotate Keys Periodically

- Change webhook secrets monthly
- Rotate API keys quarterly
- Update credentials and redeploy

## Verification

### Check Current Configuration

```ruby
rails console

# See which credentials are loaded
Rails.application.credentials.dig(:razorpay, :key_id)
# => "rzp_test_..." (development)
# => "rzp_live_..." (production)

# Check environment
Rails.env
# => "development" or "production"
```

### Test API Connection

```ruby
rails console

# Test in current environment
order = Razorpay::Order.create(
  amount: 100,
  currency: 'INR',
  receipt: 'test'
)
puts order.id
# => "order_xxxxxxxxxxxxx"
```

## Troubleshooting

### "Missing master key"

```bash
# Development - recreate
echo "$(openssl rand -hex 16)" > config/credentials/development.key

# Production - set ENV variable
export RAILS_MASTER_KEY=your_key_here
```

### "Key not found" in production

```bash
# Check which file Rails is trying to load
RAILS_ENV=production rails runner "puts Rails.application.credentials.key_id"

# Verify master key is set
echo $RAILS_MASTER_KEY
```

### "Cannot decrypt credentials"

The master key doesn't match. You need the correct master key that was used to encrypt the file.

## Production Deployment Checklist

- [ ] Set `RAILS_MASTER_KEY` environment variable on server
- [ ] Uploaded `config/credentials/production.yml.enc` to server
- [ ] Verified `razorpay.key_id` starts with `rzp_live_`
- [ ] Webhook URL configured as HTTPS in Razorpay Dashboard
- [ ] `force_ssl = true` in production.rb
- [ ] Tested one payment in production (small amount)
- [ ] Monitoring alerts set up for payment failures

## Summary

**Recommended Structure:**

```
development:  rzp_test_xxxxxxxxxxxxx (test mode)
production:    rzp_live_xxxxxxxxxxxxx (live mode)
test:          rzp_test_xxxxxxxxxxxxx (test mode)
```

**Best Practice:**
- Separate credential files per environment
- Master key via ENV variable in production
- Never commit keys to git
- Regular key rotation
