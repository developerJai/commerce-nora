# Razorpay Integration - Setup Guide

## Overview

The Razorpay integration allows customers to pay for their orders online using UPI, Credit/Debit cards, Netbanking, and other payment methods. The implementation includes:

- **Frontend**: Razorpay Checkout.js popup for seamless payment experience
- **Backend**: Order creation, payment verification, and webhook handling
- **Security**: Signature verification for both frontend callbacks and webhooks
- **Audit Trail**: Complete payment logging for debugging and compliance

## Architecture

### Payment Flow

```
1. Customer selects "Pay Online" at checkout
   ↓
2. Order created with status: pending, payment_status: pending
   ↓
3. Razorpay order created via API
   ↓
4. Razorpay Checkout.js popup opens
   ↓
5. Customer completes payment
   ↓
6. Two parallel paths:
   a) Frontend callback (immediate)
   b) Webhook (1-5 seconds delay, source of truth)
   ↓
7. Payment verified via HMAC signature
   ↓
8. Order marked as paid and confirmed
   ↓
9. Cart cleared, customer redirected to order page
```

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| Order Model | `app/models/order.rb` | Razorpay order creation, payment verification |
| PaymentLog Model | `app/models/payment_log.rb` | Audit trail for all payment events |
| WebhooksController | `app/controllers/razorpay/webhooks_controller.rb` | Handle async Razorpay events |
| CallbacksController | `app/controllers/razorpay/callbacks_controller.rb` | Handle frontend callbacks |
| CheckoutsController | `app/controllers/checkouts_controller.rb` | Initiate payment flow |
| Checkout View | `app/views/checkouts/confirm.html.erb` | Payment method selection UI |

## Setup Instructions

### 1. Install Dependencies

The `razorpay` gem is already added. Run:

```bash
bundle install
```

### 2. Configure Credentials

#### Option A: Interactive Setup (Recommended)

```bash
rails razorpay:setup_credentials
```

#### Option B: Manual Configuration

Edit credentials:

```bash
rails credentials:edit
```

Add:

```yaml
razorpay:
  key_id: rzp_test_xxxxxxxxxxxxx
  key_secret: xxxxxxxxxxxxxxxxxxxx
  webhook_secret: xxxxxxxxxxxxxxxx
```

For development, you can also use environment variables:

```bash
export RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
export RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxx
export RAZORPAY_WEBHOOK_SECRET=xxxxxxxxxxxxxxxx
```

### 3. Run Migrations

```bash
rails db:migrate
```

This creates:
- `razorpay_order_id`, `razorpay_payment_id`, `payment_signature` on orders
- `payment_logs` table for audit trail

### 4. Test Configuration

```bash
rails razorpay:test_config
```

This verifies:
- ✅ Credentials are configured
- ✅ API connection works
- ✅ Webhook secret is set

### 5. Setup Razorpay Dashboard

1. **Login to Razorpay Dashboard** (https://dashboard.razorpay.com)

2. **Get API Keys**:
   - Go to Settings → API Keys
   - Generate Key ID and Key Secret
   - Copy to your Rails credentials

3. **Configure Webhook**:
   - Go to Settings → Webhooks
   - Add New Webhook:
     - **URL**: `https://yourdomain.com/razorpay/webhook`
     - **Secret**: Generate a random secret and add to credentials
     - **Events**: Select these:
       - ✅ `payment.captured`
       - ✅ `payment.failed`
       - ✅ `order.paid`
       - ✅ `refund.processed` (optional)

4. **Enable Payment Methods**:
   - Go to Settings → Payment Methods
   - Enable: Cards, UPI, Netbanking, Wallets as needed

### 6. Configure SSL (Production)

In `config/environments/production.rb`:

```ruby
config.force_ssl = true
```

## Testing

### Test Cards

Use these test card numbers in Razorpay test mode:

| Scenario | Card Number | Expiry | CVV | OTP |
|----------|-------------|--------|-----|-----|
| ✅ Success | 5267 3181 8797 5449 | Any future | Any | 1234 |
| ❌ Failure | 4111 1111 1111 1111 | Any future | Any | - |
| ⚠️ Low Balance | 5104 0600 0000 0008 | Any future | Any | - |

### Test UPI

- Success: `success@razorpay`
- Failure: `failure@razorpay`

### Test Flow

1. Add items to cart
2. Proceed to checkout
3. Select "Pay Online"
4. Enter test card details
5. Complete payment
6. Verify:
   - Order status is "confirmed"
   - Payment status is "paid"
   - Inventory decremented
   - Payment log created

## Security Features

### 1. Signature Verification

All payments are verified using HMAC-SHA256:

```ruby
generated_signature = OpenSSL::HMAC.hexdigest(
  'SHA256',
  key_secret,
  "#{order_id}|#{payment_id}"
)

# Must match exactly with received signature
ActiveSupport::SecurityUtils.secure_compare(generated_signature, received_signature)
```

### 2. Webhook Verification

Webhooks are verified using the `X-Razorpay-Signature` header:

```ruby
expected_signature = OpenSSL::HMAC.hexdigest(
  'SHA256',
  webhook_secret,
  request.body.read
)
```

### 3. Amount Verification

Payment amount is always verified against order total:

```ruby
if payment['amount'] != (order.total_amount * 100).to_i
  # Reject - possible tampering
end
```

### 4. Idempotency

Duplicate webhooks are handled gracefully:

```ruby
return if order.payment_status == 'paid'
```

## Troubleshooting

### Common Issues

#### 1. "Invalid API key"

- Check that credentials are properly set
- Verify key ID starts with `rzp_test_` (test) or `rzp_live_` (production)
- Run `rails razorpay:test_config`

#### 2. "Webhook signature verification failed"

- Ensure webhook secret matches between Razorpay Dashboard and credentials
- Check that `request.body.rewind` is called after reading
- Verify no middleware is modifying request body

#### 3. "Order not found" in webhook

- Check `razorpay_order_id` is being stored correctly
- Verify webhook payload contains correct order_id
- Check PaymentLog for error details

#### 4. Payment captured but order not confirmed

- Check webhook is receiving events
- Verify webhook URL is accessible from internet
- Check server logs for webhook processing errors
- Frontend callback should handle this as fallback

### Debug Tools

Check payment logs:

```ruby
# All events for an order
PaymentLog.where(order_id: 123).order(:created_at)

# Failed events
PaymentLog.failed.recent

# Webhook events
PaymentLog.where("event_type LIKE 'webhook%'")
```

Check order status:

```ruby
order = Order.find_by(razorpay_order_id: "order_xxxx")
order.payment_status
order.razorpay_payment_id
order.payment_logs.count
```

## Production Checklist

- [ ] Use live keys (rzp_live_xxx) in production credentials
- [ ] Configure webhook URL with HTTPS
- [ ] Enable force_ssl in production
- [ ] Set up monitoring for failed payments
- [ ] Configure email notifications for failed webhooks
- [ ] Test refund flow
- [ ] Add error tracking (Sentry/Honeybadger)
- [ ] Monitor PaymentLog for anomalies
- [ ] Set up alerts for high failure rates

## API Reference

### Order Model Methods

```ruby
# Create Razorpay order
order.create_razorpay_order!

# Verify payment
order.verify_razorpay_payment!(payment_id, signature)

# Mark failed
order.mark_payment_failed!(error_message)

# Check if can retry
order.can_retry_payment? # => true/false

# Check payment method
order.razorpay? # => true/false
order.paid? # => true/false
```

### Webhook Events Handled

- `payment.captured` - Payment successful
- `payment.failed` - Payment failed
- `order.paid` - Order fully paid
- `refund.processed` - Refund completed

### Routes

| Method | Path | Controller#Action |
|--------|------|-------------------|
| POST | /razorpay/webhook | webhooks#handle |
| GET | /razorpay/success | callbacks#success |
| GET | /razorpay/failure | callbacks#failure |

## Support

For Razorpay-specific issues:
- Razorpay Docs: https://razorpay.com/docs/
- Razorpay Support: support@razorpay.com

For integration issues:
- Check PaymentLog records
- Review server logs
- Verify webhook configuration

## Additional Notes

### Multi-Vendor Orders

When a customer buys from multiple vendors:
- Separate Razorpay orders are created per vendor
- Customer completes payment for each order individually
- All orders are linked via `checkout_batch_id`

### Failed Payment Retry

Customers can retry failed payments:
- Up to 3 attempts per order
- Order status remains "pending"
- Each attempt logged in PaymentLog
- Retry button shown on order page (if implemented)

### Refunds

Refunds are processed manually via Razorpay Dashboard:
1. Admin initiates refund in Dashboard
2. Razorpay sends `refund.processed` webhook
3. Order marked as `refund_processed`
4. Admin can then cancel order if needed
