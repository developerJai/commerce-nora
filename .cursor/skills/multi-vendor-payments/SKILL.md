---
name: multi-vendor-payments
description: Multi-vendor checkout, payment processing, refunds, and payouts architecture. One customer payment covers multiple vendor orders with separate fulfillment, individual refunds, and per-vendor payouts.
---

# Multi-Vendor Payment Architecture

## Overview

Industry-standard marketplace payment system where one customer checkout creates multiple vendor orders under a single payment, with independent fulfillment, refunds, and payouts.

**Inspired by**: Amazon, Shopify Markets, Flipkart, Etsy

## Core Concept

```
Customer Checkout
       |
       v
Cart Items (from 2 vendors)
       |
       v
Order A ($600) + Order B ($400)
       |
       v
CheckoutSession (groups orders)
       |
       v
Single Razorpay Payment ($1000)
       |
       v
Each vendor fulfills independently
```

## Models

### CheckoutSession
Groups multiple vendor orders under one payment.

**Fields**:
- `batch_id`: UUID (unique, groups orders from same checkout)
- `razorpay_order_id`: Razorpay's payment order ID (unique)
- `customer_id`: Who made the purchase
- `total_amount`: Sum of all vendor orders
- `status`: pending | paid | failed | refunded | partially_refunded
- `payment_method`: cod | razorpay
- `paid_at`: When payment completed
- `failed_at`: When payment failed
- `notes`: Optional customer notes

**Key Methods**:
- `mark_as_paid!(payment_id)` - Updates status and timestamp
- `mark_as_failed!(error_message)` - Records failure
- `update_refund_status!` - Updates to partially_refunded/refunded

### Order (Enhanced)
Each vendor gets their own order.

**New Fields**:
- `checkout_session_id`: Links to CheckoutSession
- `checkout_batch_id`: Legacy UUID (same as batch_id)
- `razorpay_payment_id`: Individual payment reference
- `payment_status`: pending | paid | failed | refunded
- `refund_status`: not_refunded | initiated | paid | failed
- `refund_amount`: How much refunded
- `refund_reason`: Why cancelled/refunded
- `platform_fee_amount`: Platform commission deducted
- `gateway_fee_amount`: Payment processor fee
- `gateway_gst_amount`: GST on gateway fee (18%)
- `vendor_earnings`: Net amount vendor receives
- `payout_status`: pending | requested | paid | rejected

**Relationships**:
- `belongs_to :checkout_session, optional: true`
- `belongs_to :vendor`
- `has_many :order_items`

## Payment Flow

### 1. Checkout Creation (checkouts_controller.rb)

```ruby
def create
  # Group cart items by vendor
  items_by_vendor = cart_items.group_by { |i| i.product.vendor_id }
  
  ActiveRecord::Base.transaction do
    # Create Order for each vendor
    orders = items_by_vendor.map do |vendor_id, items|
      build_vendor_order(vendor_id, items)
    end
    
    # Create CheckoutSession
    checkout_session = CheckoutSession.create!(
      customer: current_customer,
      batch_id: SecureRandom.uuid,
      total_amount: orders.sum(&:total_amount),
      status: 'pending',
      payment_method: 'razorpay'
    )
    
    # Link orders to session
    orders.each { |o| o.update!(checkout_session: checkout_session) }
    
    # Create ONE Razorpay order for total
    razorpay_order = Razorpay::Order.create(
      amount: checkout_session.total_amount * 100, # paise
      currency: 'INR',
      notes: { checkout_session_id: checkout_session.id }
    )
    
    checkout_session.update!(razorpay_order_id: razorpay_order.id)
  end
end
```

### 2. Payment Success (razorpay/callbacks_controller.rb)

```ruby
def success
  checkout_session = CheckoutSession.find_by(
    razorpay_order_id: params[:razorpay_order_id]
  )
  
  orders = checkout_session.orders
  
  ActiveRecord::Base.transaction do
    orders.each do |order|
      order.update!(
        payment_status: 'paid',
        razorpay_payment_id: params[:razorpay_payment_id]
      )
      order.place! # Confirm order, decrement inventory
    end
    
    checkout_session.mark_as_paid!(params[:razorpay_payment_id])
  end
end
```

### 3. Order Fulfillment

Each vendor manages their orders independently:

```
Status Flow:
pending → confirmed → processing → shipped → delivered

Actions:
- pending → confirmed: Vendor accepts order
- confirmed → processing: Vendor starts packing
- processing → shipped: Vendor adds tracking, ships
- shipped → delivered: Customer receives order
```

## Refund Architecture

### Partial Refunds (Key Feature)

Customer can cancel individual orders from a multi-order payment:

**Scenario**:
```
Payment: $1000
├─ Order A (Vendor 1): $600
└─ Order B (Vendor 2): $400

Customer cancels Order A only:
├─ Refund $600 via Razorpay partial refund
├─ Order A: cancelled + refunded
└─ Order B: remains active
```

**Process**:
1. Admin cancels order in admin panel
2. System initiates refund (status: initiated)
3. Admin processes partial refund via Razorpay dashboard
4. Admin marks refund as paid with transaction ID
5. CheckoutSession updates to `partially_refunded`

**Code** (order.rb):
```ruby
def cancel!(reason)
  transaction do
    update!(
      status: 'cancelled',
      cancellation_reason: reason
    )
    
    if paid?
      update!(
        refund_status: 'initiated',
        refund_amount: total_amount,
        refund_reason: reason,
        refund_initiated_at: Time.current
      )
      
      checkout_session.update_refund_status!
    end
    
    restore_inventory!
  end
end
```

## Payout Architecture

### Per-Vendor Payouts

Each vendor gets paid separately for their orders:

**Fee Calculation**:
```
Order Total: $1000
├─ Platform Fee (10%): $100
├─ Gateway Fee (2%): $20
├─ GST on Gateway (18%): $3.60
└─ Vendor Earnings: $876.40
```

**Formula**:
- Platform Fee = Total × Platform Commission %
- Gateway Fee = Total × Gateway Fee %
- Gateway GST = Gateway Fee × 18%
- Vendor Earnings = Total - (Platform + Gateway + GST)

**Payout Flow**:
1. Order delivered
2. System calculates vendor earnings
3. Vendor requests payout
4. Admin processes payout (bank transfer)
5. Order marked: `payout_status: paid`

**Key Files**:
- `app/models/order.rb` - Fee calculations
- `app/models/platform_fee_config.rb` - Fee rates

## Tax Calculation

### Per-Item GST

Each item taxed based on HSN code:

```ruby
# In Order model
def calculate_tax
  order_items.sum do |item|
    rate = item.product.hsn_code&.gst_rate || 3.0
    item.total_price * rate / 100.0
  end
end
```

**Display Locations**:
- Checkout page: Per-item tax badge + amount
- Order confirmation: Per-item breakdown
- Admin order details: Tax column
- Invoices: GST % and amount

## Controllers

| Controller | Purpose |
|------------|---------|
| `checkouts_controller.rb` | Creates checkout session, handles COD/Razorpay |
| `razorpay/callbacks_controller.rb` | Success/failure callbacks |
| `razorpay/webhooks_controller.rb` | Async webhook processing |
| `admin/orders_controller.rb` | Cancel, refund, ship, deliver actions |

## Database Changes

### Migration: Create CheckoutSessions
```ruby
create_table :checkout_sessions do |t|
  t.string :batch_id, null: false
  t.string :razorpay_order_id
  t.references :customer, null: false
  t.decimal :total_amount, precision: 10, scale: 2
  t.string :status, default: 'pending'
  t.string :payment_method
  t.datetime :paid_at
  t.datetime :failed_at
  t.text :error_message
  t.text :notes
  t.timestamps
end

add_index :checkout_sessions, :batch_id, unique: true
add_index :checkout_sessions, :razorpay_order_id, unique: true
```

### Migration: Update Orders
```ruby
# Add checkout session reference
add_reference :orders, :checkout_session, null: true

# Remove unique constraint from razorpay_order_id
remove_index :orders, :razorpay_order_id
add_index :orders, :razorpay_order_id  # Non-unique
```

## Industry Standards

This architecture follows:

- **Amazon**: Single payment, multiple sellers, separate shipments
- **Shopify Markets**: One checkout session, split by location
- **Flipkart**: Same model - one payment, vendor splits
- **Etsy**: Multi-shop checkout, independent refunds

## Testing Checklist

- [ ] Single vendor checkout (COD)
- [ ] Single vendor checkout (Razorpay)
- [ ] Multi-vendor checkout (2+ vendors)
- [ ] Payment success callback
- [ ] Payment failure handling
- [ ] Partial refund (cancel 1 of 2 orders)
- [ ] Full refund (cancel all orders)
- [ ] Per-vendor shipping calculation
- [ ] Tax calculation per item
- [ ] Vendor earnings calculation
- [ ] Payout workflow

## Key Points

1. **CheckoutSession**: Central entity tracking payment state across multiple orders
2. **Partial Refunds**: Core feature - cancel individual orders independently
3. **Fee Transparency**: Platform/gateway fees clearly shown to vendors
4. **Inventory**: Only decremented after payment confirmed
5. **Audit Trail**: PaymentLog records all events per order
6. **Backward Compatible**: Legacy orders work without checkout_session

## Related Files

- `app/models/checkout_session.rb`
- `app/models/order.rb`
- `app/controllers/checkouts_controller.rb`
- `app/controllers/razorpay/callbacks_controller.rb`
- `app/controllers/razorpay/webhooks_controller.rb`
- `docs/multi_vendor_payment_architecture.md` (detailed design doc)
