# Multi-Vendor Payment Architecture

## Overview

This document describes the industry-standard architecture for handling payments in a multi-vendor marketplace where:
- One customer payment covers multiple vendor orders
- Each vendor manages their own order fulfillment
- Refunds must be handled per-order
- Payouts are processed per-vendor

## Core Concepts

### 1. Checkout Session (Payment Group)

```
┌─────────────────────────────────────────────────────────────┐
│                    CHECKOUT SESSION                          │
│  (Groups multiple vendor orders under one payment)          │
├─────────────────────────────────────────────────────────────┤
│  - batch_id: UUID (groups orders)                           │
│  - razorpay_order_id: String (single payment ID)           │
│  - total_amount: Decimal (sum of all orders)               │
│  - customer_id: Integer                                    │
│  - status: pending | paid | failed | refunded              │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ creates multiple
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Order A (Vendor 1)    │    Order B (Vendor 2)              │
│  - order_number        │    - order_number                  │
│  - vendor_id = 1       │    - vendor_id = 2                 │
│  - subtotal, tax, etc  │    - subtotal, tax, etc            │
│  - checkout_batch_id   │    - checkout_batch_id             │
│  - razorpay_order_id   │    - razorpay_order_id             │
│  - payment_status      │    - payment_status                │
└─────────────────────────────────────────────────────────────┘
```

### 2. Payment Flow

#### 2.1 Checkout Creation
1. Group cart items by vendor
2. Create Order records for each vendor (status: pending)
3. Create ONE Razorpay order for the total amount
4. Link all orders to the same `razorpay_order_id`
5. Return single payment config to frontend

#### 2.2 Payment Success
1. Razorpay callback/webhook receives payment confirmation
2. Find ALL orders with the same `razorpay_order_id`
3. Mark all orders as `payment_status: paid`
4. Place all orders (confirm them)
5. Decrement inventory for all items

#### 2.3 Payment Failure
1. Mark all orders as `payment_status: failed`
2. Keep orders in pending state (allow retry)
3. Do not decrement inventory

### 3. Refund Architecture

#### 3.1 The Problem
- One Razorpay payment = multiple vendor orders
- Customer wants to cancel/refund Order A but keep Order B
- Razorpay only allows refunding the entire payment or partial amounts

#### 3.2 Solution: Partial Refunds

```
Customer Payment: ₹1000 (Order A: ₹600 + Order B: ₹400)

Scenario 1: Cancel Order A only
├─ Refund ₹600 to customer via Razorpay partial refund
├─ Mark Order A as cancelled
├─ Mark Order A as refunded
└─ Order B remains active

Scenario 2: Cancel both orders
├─ Refund ₹1000 to customer via Razorpay full refund
├─ Mark both orders as cancelled
└─ Mark both orders as refunded
```

#### 3.3 Refund Implementation

```ruby
# In Order model
def can_refund?
  paid? && !refunded? && !refund_initiated?
end

def initiate_refund!(amount:, reason:)
  return false unless can_refund?
  
  # For multi-vendor orders, check if partial refund is possible
  sibling_orders = Order.where(razorpay_order_id: razorpay_order_id, payment_status: 'paid')
  total_paid = sibling_orders.sum(:total_amount)
  
  # Create refund record
  update!(
    refund_status: 'initiated',
    refund_amount: amount,
    refund_reason: reason,
    refund_initiated_at: Time.current
  )
  
  # Admin must process partial refund via Razorpay dashboard
  # Then mark as paid with transaction ID
end
```

### 4. Payout Architecture

#### 4.1 Vendor Earnings Calculation

Each order tracks:
- `platform_fee_amount`: Commission deducted
- `gateway_fee_amount`: Payment processor fee
- `gateway_gst_amount`: GST on gateway fee
- `vendor_earnings`: Net amount to vendor

```
Order Total: ₹1000
├─ Platform Fee (10%): ₹100
├─ Gateway Fee (2%): ₹20
├─ GST on Gateway (18%): ₹3.60
└─ Vendor Earnings: ₹876.40
```

#### 4.2 Payout Flow

1. Order delivered
2. Calculate vendor earnings (fees deducted)
3. Vendor requests payout for eligible orders
4. Admin approves and processes payout
5. Mark orders as `payout_status: paid`

#### 4.3 Partial Cancellation Impact

If Order A is cancelled and refunded:
- Order A: No payout (vendor earns ₹0)
- Order B: Normal payout process (vendor earns ₹876.40)

### 5. Database Schema Updates

```ruby
# Orders table already has:
# - razorpay_order_id (links multiple orders to one payment)
# - checkout_batch_id (groups orders from same checkout)
# - refund_status, refund_amount, etc.

# Additional fields needed:
add_column :orders, :parent_order_id, :integer, null: true
# For tracking split orders if needed in future
```

### 6. Key Principles

1. **Single Payment, Multiple Orders**: One Razorpay order ID links multiple internal orders
2. **Independent Order Management**: Each vendor manages their order separately
3. **Separate Payouts**: Each vendor gets paid separately for their orders
4. **Partial Refunds**: Support cancelling individual orders from a multi-order payment
5. **Audit Trail**: PaymentLog tracks all events per order

### 7. Code Structure

```ruby
# CheckoutsController
def create
  # Create orders for each vendor
  orders = create_vendor_orders
  
  if razorpay_payment?
    # Create single Razorpay order for total
    razorpay_order = create_razorpay_order(total_amount)
    
    # Link all orders to same payment
    orders.each { |o| o.update!(razorpay_order_id: razorpay_order.id) }
  end
end

# RazorpayCallbacksController
def success
  orders = Order.where(razorpay_order_id: params[:razorpay_order_id])
  
  orders.each do |order|
    order.mark_as_paid!(payment_id, signature)
    order.place!
  end
end

# Order model
def mark_as_paid!(payment_id, signature)
  update!(
    payment_status: 'paid',
    razorpay_payment_id: payment_id,
    payment_signature: signature
  )
end

def cancel!(reason)
  return false unless can_cancel?
  
  transaction do
    update!(status: 'cancelled', cancellation_reason: reason)
    
    if paid? && refundable?
      initiate_refund!(amount: total_amount, reason: reason)
    end
    
    restore_inventory!
  end
end
```

### 8. Industry Standards

- **Amazon**: Single payment for multiple sellers, separate shipments, separate refunds
- **Shopify Markets**: One payment session, split fulfillment, per-order refunds
- **Etsy**: Single checkout, multiple shops, independent refunds per shop
- **Flipkart**: Same architecture - one payment, split by seller, separate refunds

### 9. Implementation Checklist

- [x] Single Razorpay order for multiple vendor orders
- [x] Link orders via `razorpay_order_id`
- [x] Callback processes all orders with same payment ID
- [x] Per-vendor order management
- [x] Per-vendor shipping calculation
- [x] Tax calculation per item/vendor
- [x] Refund support per order
- [x] Payout calculation per vendor
- [x] Payment logging per order
- [ ] Partial refund processing via admin
- [ ] Refund webhook handling
- [ ] Payout workflow automation
