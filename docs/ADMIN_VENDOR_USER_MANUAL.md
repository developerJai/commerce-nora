# User Manual: Admin & Vendor Portal Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Understanding User Roles](#understanding-user-roles)
3. [Admin Dashboard](#admin-dashboard)
4. [Product Management](#product-management)
5. [Inventory Management](#inventory-management)
6. [How to Refill Stock](#how-to-refill-stock)
7. [Order Management](#order-management)
8. [Admin: SALES](#admin-sales)
   - [Checkout Sessions](#checkout-sessions)
   - [Refunds](#refunds)
   - [Draft Orders](#draft-orders)
9. [PLATFORM: Vendor Payouts](#platform-vendor-payouts)
10. [MANAGEMENT: HSN Codes](#management-hsn-codes)
11. [Vendor Management (Admin Only)](#vendor-management-admin-only)
12. [Reports & Analytics](#reports--analytics)
13. [Support Tickets](#support-tickets)
14. [Common Workflows](#common-workflows)
15. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Logging In

#### For Administrators:
1. Navigate to `/admin/login`
2. Enter your admin email and password
3. You'll be redirected to the Admin Dashboard

#### For Vendors:
1. Navigate to `/vendor/login`
2. Enter your vendor credentials
3. You'll access the admin panel with vendor-restricted views

### Navigation

The left sidebar contains all main sections:
- **Dashboard** - Overview and key metrics
- **Products** - Manage your product catalog
- **Inventory** - Stock management and alerts
- **Orders** - View and process customer orders
- **Customers** - Customer management (Admin only)
- **Vendors** - Vendor management (Admin only)
- **Categories** - Product categories (Admin only)
- **Coupons** - Discount codes
- **Reviews** - Product reviews
- **Support Tickets** - Customer service
- **Reports** - Sales and analytics
- **Settings** - Store configuration (Admin only)

---

## Understanding User Roles

### Administrator (Admin)
**Full platform access with complete control:**
- ✅ Manage all products across all vendors
- ✅ Access all orders and customer data
- ✅ Manage vendors and their payouts
- ✅ Configure store settings, categories, and fees
- ✅ View all reports and analytics
- ✅ Manage admin users and permissions
- ✅ Impersonate vendors to see their view

### Vendor
**Restricted access to own data only:**
- ✅ Manage own products only
- ✅ View and manage orders for own products
- ✅ Access own inventory and stock reports
- ✅ View own earnings and request payouts
- ✅ Respond to reviews on own products
- ✅ Create and view support tickets
- ❌ Cannot access other vendors' data
- ❌ Cannot manage categories or store settings
- ❌ Cannot access customer personal data
- ❌ Cannot view platform-wide reports

### Role Indicators
Look for these indicators in the interface:
- **"Acting as [Vendor Name]"** - Admin is currently viewing as a specific vendor
- **Vendor-only sections** - Some menu items are hidden from vendor view
- **Filtered data** - Vendors only see their own products/orders/reviews

---

## Admin Dashboard

### Dashboard Overview

When you log in, you'll see the Dashboard with key metrics:

#### For Admins:
- **Total Orders** - All orders placed on the platform
- **Total Revenue** - Platform-wide revenue
- **Total Products** - Total product count
- **Total Customers** - Registered customer count
- **Total Vendors** - Number of active vendors
- **Low Stock Alerts** - Products needing attention
- **Open Tickets** - Pending support requests
- **Pending Reviews** - Reviews awaiting approval
- **Recent Orders** - Last 5 orders

#### For Vendors:
- **My Orders** - Orders containing your products
- **My Revenue** - Your earnings from orders
- **My Products** - Your product count
- **Out of Stock** - Your products with zero inventory
- **Low Stock** - Your products below 10 units
- **Open Tickets** - Your support tickets
- **Pending Reviews** - Reviews on your products

### Quick Actions
- View pending orders requiring confirmation
- Check orders awaiting shipment
- Monitor today's sales and revenue

---

## Product Management

### Creating a New Product

1. **Navigate to Products → New Product**
2. **Fill in Basic Information:**
   - **Product Name** - Display name (e.g., "Gold Pearl Earrings")
   - **Slug** - URL-friendly name (auto-generated if blank)
   - **Category** - Select from dropdown (determines available attributes)
   - **HSN Code** - For tax purposes
   - **Vendor** - Select vendor (Admin only)
   - **Short Description** - Brief summary for product cards
   - **Full Description** - Detailed product information
   - **SKU** - Auto-generated if blank
   - **Base Price** - Reference price (actual price set per variant)

3. **Set Product Attributes** (Category-dependent):
   - Fields appear based on selected category
   - Example: Material, Style, Occasion for jewelry
   - Required fields marked with red asterisk (*)

4. **Create First Variant (Required):**
   Every product needs at least one variant with:
   - **Variant Name** - Auto-generated from color/size if blank
   - **Variant Attributes** - Color, Size, etc. (category-dependent)
   - **Selling Price (₹)** - Customer-facing price
   - **MRP / Compare Price (₹)** - Crossed-out original price (must be ≥ Selling Price)
   - **Stock Quantity** - Available inventory
   - **Weight** - In grams for shipping
   - **SKU** - Auto-generated if blank
   - **Track Inventory** - Check to auto-deduct stock on orders
   - **Reorder Point** - Alert threshold (default: 10)
   - **Variant Image** - Shown on product cards

5. **Upload Product Images:**
   - Add up to 15 images
   - First image used as primary
   - Drag and drop or click to upload
   - Hover and click "Remove" to delete existing images

6. **Set Product Status:**
   - ☑️ **Active** - Visible on storefront
   - ☑️ **Featured** - Show on homepage (if configured)
   - ☑️ **Hot Selling** - Highlight as popular item

7. **Click "Create Product"**

**⚠️ Important Notes:**
- **MRP must be ≥ Selling Price** - System will reject if MRP is lower
- **Category determines attributes** - Select category first to see relevant fields
- **At least one variant required** - Product won't appear without variants

### Managing Products

#### Product List View
- **Filter by Status:** Active, Draft, Featured, Hot Selling
- **Search:** By name, SKU, or category
- **Sort:** By name, price, or stock level
- **Bulk Actions:** Enable/disable multiple products

#### Product Detail View
Access by clicking on a product name. Shows:
- Product information and attributes
- **Variants Table** with stock status:
  - 🟢 **In Stock** - Normal display
  - 🟡 **Low Stock** - Yellow warning (≤ 10 units)
  - 🔴 **Out of Stock** - Red badge (0 units)
- Actions: Edit, Enable/Disable, Delete per variant

### Adding Variants to Existing Products

1. From product detail page, click **"Add Variant"**
2. Fill in variant details (same fields as above)
3. **Pricing Validation:**
   - Selling Price: What customer pays
   - MRP: Must be equal or higher than Selling Price
   - If MRP > Selling Price, discount % shown automatically
4. Click **"Save Variant"**

### Editing Variants

1. Click **"Edit"** on any variant
2. Modify fields as needed
3. **Stock Quantity:** Can be adjusted here (use Inventory Management for bulk adjustments)
4. **Active Toggle:** Enable/disable without deleting

### Disabling Products/Variants

**To temporarily hide from storefront:**
- Click **"Disable"** button (toggles to "Enable" when inactive)
- Product disappears from storefront immediately
- Existing orders are not affected

**⚠️ Important:** Disabling a product does NOT:
- Remove it from customer carts
- Cancel pending orders containing it
- Affect payments in progress

---

## Inventory Management

### Understanding Inventory Levels

The system tracks three stock statuses per variant:

| Status | Stock Level | Action Needed |
|--------|-------------|---------------|
| 🟢 **In Stock** | > reorder_point | None |
| 🟡 **Low Stock** | ≤ reorder_point, > 0 | Reorder soon |
| 🔴 **Out of Stock** | 0 | Urgent reorder! |

### Accessing Inventory Dashboard

Navigate to **Inventory** from the sidebar to see:
- **Total Items** - All your variants
- **Out of Stock** - Zero inventory count
- **Low Stock** - Below 10 units count
- **Needs Reorder** - At or below reorder_point

### Inventory Settings per Variant

When editing a variant, you can configure:

**Stock Management:**
- **Stock Quantity** - Current available units
- **Track Inventory** - Auto-deduct on orders (recommended: ON)
- **Reorder Point** - Alert threshold (e.g., 10 units)
- **Reorder Quantity** - Suggested restock amount (e.g., 50 units)

### Adjusting Stock (Single Item)

1. From Inventory list, click **"Adjust"** on a variant
2. You'll see:
   - Current stock quantity
   - Adjustment form
3. **Enter Adjustment:**
   - Positive number to add stock (e.g., `50` for restocking 50 units)
   - Negative number to remove stock (e.g., `-5` for removing 5 units)
4. **Select Reason:**
   - **Restock/Purchase** - New inventory arrival
   - **Sale** - Manual order entry
   - **Return** - Customer return
   - **Damage** - Damaged/unsellable goods
   - **Correction** - Fixing inventory count
5. **Add Notes** (optional) - For your reference
6. Click **"Update Stock"**

**Result:** Stock updates immediately with audit trail

### Bulk Restocking

When multiple items need reordering:

1. Click **"Bulk Restock"** button on Inventory page
2. System shows all items at or below reorder point
3. Each row shows:
   - Current stock
   - Reorder point
   - Pre-filled suggested reorder quantity
4. **Adjust quantities** as needed (based on supplier availability)
5. Click **"Restock Selected Items"**
6. All adjustments happen in one action

### Reorder Report

Generate purchase orders for suppliers:

1. Click **"Reorder Report"**
2. View list of items needing reorder with:
   - SKU
   - Current stock
   - Reorder point
   - Suggested quantity
   - Estimated cost (60% of price)
3. **Download CSV** to send to suppliers
4. Use this as your purchase order

### Adjustment History

View complete audit trail:

1. Click **"Adjustment History"**
2. Shows all stock changes with:
   - Date/Time
   - Product & Variant
   - Quantity change (+/-)
   - Before/After stock levels
   - Reason
   - User who made adjustment
3. **Filter by:** Reason type or specific product

### Stock Deduction on Orders

**Automatic Process:**
- When order is placed, stock auto-deducts if "Track Inventory" is ON
- Deducts quantity for each variant
- Creates "sale" adjustment record
- Stock cannot go below 0 (order will fail)

**⚠️ Important:** 
- Stock deducts when order is **placed**, not when payment completes
- If payment fails, stock is already deducted
- Manual restocking needed if payment fails and you want to return stock

### Inventory Best Practices

✅ **DO:**
- Set realistic reorder points based on sales velocity
- Use bulk restock for efficiency
- Check reorder report weekly
- Keep adjustment notes for audit purposes
- Enable "Track Inventory" on all sellable variants

❌ **DON'T:**
- Ignore low stock alerts
- Manually edit stock without using adjustment form (loses audit trail)
- Set reorder_point to 0 (misses low stock warnings)

---

## How to Refill Stock

### Overview

Refilling stock (also called "restocking" or "inventory adjustment") is the process of adding new inventory to your product variants. The system tracks every stock change with an audit trail for accountability.

### Methods to Refill Stock

#### Method 1: Single Item Adjustment (Quick)

**Use when:** Adjusting one specific variant

**Steps:**

1. **Navigate to Inventory**
   - Click **"Inventory"** in left sidebar
   - Or go to Products → click on product → find variant

2. **Find the Variant**
   - Use search box to find by SKU or product name
   - Or browse the list
   - Look for 🔴 Out of Stock or 🟡 Low Stock badges

3. **Click "Adjust" Button**
   - Located in the "Actions" column
   - Opens the stock adjustment form

4. **Fill Adjustment Form:**

   **Current Stock:** Shows existing quantity (read-only)
   
   **Quantity Change:** Enter positive number to ADD stock
   - Example: `50` (adds 50 units)
   - Example: `100` (adds 100 units)
   
   **Reason:** Select from dropdown:
   - **Restock / Purchase** ← Most common for refilling
   - **Return** - Customer returned items
   - **Initial** - First time stock entry
   - **Transfer** - Stock moved from another location
   - **Correction** - Fixing incorrect count
   
   **Notes:** (Optional but recommended)
   - Supplier name: "ABC Suppliers"
   - Invoice number: "INV-2024-001"
   - Date received: "March 1, 2024"
   - Any other relevant info

5. **Click "Update Stock"**
   - Stock updates immediately
   - New quantity = Old quantity + Adjustment
   - System creates audit record

**Example:**
```
Current Stock: 5
Quantity Change: 50
Reason: Restock / Purchase
Notes: Received from ABC Suppliers, Invoice #12345

Result: New stock = 55 (5 + 50)
```

---

#### Method 2: Bulk Restock (Efficient)

**Use when:** Multiple items arrived from supplier

**Steps:**

1. **Navigate to Inventory → Click "Bulk Restock"**
   - Shows only items that need reordering
   - Pre-filtered: stock ≤ reorder_point

2. **Review the List**
   - Each row shows:
     - Product & Variant name
     - Current stock
     - Reorder point (alert threshold)
     - **Suggested reorder quantity** (pre-filled)

3. **Adjust Quantities**
   - Default is the reorder_quantity setting (usually 50)
   - Modify based on what you actually received
   - Example: Supplier sent 30 instead of 50? Change to 30

4. **Select All or Specific Items**
   - Checkbox in header to select all
   - Or select individual items

5. **Click "Restock Selected Items"**
   - System adjusts all selected items at once
   - Each gets "Restock" reason automatically
   - Shows success message with count

**Example Bulk Operation:**
```
Items to Restock:
☑️ Product A - Gold Variant (Current: 3, Add: 50)
☑️ Product B - Silver Variant (Current: 8, Add: 50)  
☑️ Product C - Rose Gold (Current: 0, Add: 50)

Result: 3 items restocked, total 150 units added
```

---

#### Method 3: During Variant Edit

**Use when:** Editing variant details AND updating stock

**Steps:**

1. **Products → Select Product**
2. **Click "Edit" on variant**
3. **Find "Stock Quantity" field**
4. **Change the number**
   - Old: 10
   - New: 60
   - Effectively adding 50 units
5. **Add reason in notes field** (if available)
6. **Save Variant**

**⚠️ Warning:** This method bypasses the adjustment tracking system. Use Method 1 or 2 for proper audit trail.

---

### Stock Adjustment Types & When to Use

| Reason | Use Case | Example |
|--------|----------|---------|
| **Restock** | New inventory from supplier | Weekly supplier delivery |
| **Return** | Customer returned sellable item | Customer returned undamaged earrings |
| **Initial** | First time adding stock | New product launch |
| **Correction** | Fix inventory count after audit | Physical count shows 45, system shows 48 |
| **Transfer** | Moving stock between warehouses | Moved 20 units to retail store |

---

### Understanding Stock Status Indicators

After refilling, check the status changes:

**Before Refill:**
- 🔴 **Out of Stock** (0 units) - Product hidden from storefront
- 🟡 **Low Stock** (≤10 units) - Warning badge shown

**After Refill:**
- 🟢 **In Stock** (> reorder_point) - Normal display

**Status Updates Automatically:**
- No manual action needed
- Storefront updates within seconds
- Customers can purchase immediately

---

### Stock Refill Best Practices

✅ **DO:**
- **Verify physical count** before adjusting
- **Add supplier details** in notes (invoice numbers)
- **Use bulk restock** for efficiency with multiple items
- **Check reorder report** weekly to stay ahead
- **Update reorder_point** based on sales velocity
  - Fast-selling items: Lower point (reorder sooner)
  - Slow-selling items: Higher point (less frequent)

❌ **DON'T:**
- **Don't guess quantities** - Count actual items
- **Don't forget notes** - Makes audits impossible
- **Don't delay restocking** - Lost sales when out of stock
- **Don't adjust without reason** - Always select appropriate reason

---

### Tracking Your Refills

**View Adjustment History:**

1. **Inventory → Click "Adjustment History"**
2. **See all your stock changes:**
   - Date & Time
   - Product & Variant
   - Quantity added/removed
   - Before → After counts
   - Reason selected
   - Who made the adjustment

3. **Filter by:**
   - Reason type (Restock, Return, etc.)
   - Date range
   - Specific product

**Use Cases for History:**
- Verify supplier deliveries
- Track return rates
- Audit inventory accuracy
- Identify shrinkage (theft/damage)

---

### Reorder Point Strategy

**What is Reorder Point?**
The stock level that triggers "Low Stock" warning. Default is 10.

**How to Calculate Ideal Reorder Point:**

```
Reorder Point = (Daily Sales × Lead Time) + Safety Stock

Example:
- You sell 5 units/day
- Supplier takes 7 days to deliver
- You want 3 days safety buffer

Reorder Point = (5 × 7) + (5 × 3) = 35 + 15 = 50
```

**When to Adjust Reorder Point:**

| Sales Velocity | Reorder Point | Why |
|----------------|---------------|-----|
| **High** (10+/day) | 20-30 | Reorder sooner, avoid stockouts |
| **Medium** (5-10/day) | 10-15 | Default works fine |
| **Low** (1-2/day) | 5-10 | Don't overstock slow movers |

**To Change Reorder Point:**
1. Edit Variant
2. Change "Reorder Point" field
3. Save

---

### Common Refill Scenarios

#### Scenario 1: Weekly Supplier Delivery

**Situation:** Supplier delivers every Monday morning

**Process:**
```
1. Monday 9 AM: Receive delivery
2. Unpack and count items
3. Open Inventory → Bulk Restock
4. Adjust quantities if different from order
5. Add supplier invoice number in notes
6. Click "Restock Selected Items"
7. File invoice for accounting
```

#### Scenario 2: Emergency Restock

**Situation:** Popular item unexpectedly out of stock

**Process:**
```
1. Notice 🔴 Out of Stock badge
2. Contact supplier for rush delivery
3. Receive emergency stock (25 units)
4. Inventory → Adjust → Single item
5. Quantity Change: 25
6. Reason: Restock / Purchase
7. Notes: "Emergency restock, Rush delivery #5678"
8. Product immediately available for sale
```

#### Scenario 3: Customer Returns

**Situation:** Customer returns undamaged item

**Process:**
```
1. Inspect returned item (sellable condition?)
2. If yes: Add back to stock
3. Inventory → Adjust → Single item
4. Quantity Change: 1 (or however many returned)
5. Reason: Return
6. Notes: "Order #12345, customer return, reason: wrong size"
7. Stock increases, can resell item
```

#### Scenario 4: Inventory Correction

**Situation:** Physical count doesn't match system

**Process:**
```
1. Count physical stock: 45 units
2. System shows: 48 units
3. Difference: -3 units (shrinkage)
4. Inventory → Adjust
5. Quantity Change: -3
6. Reason: Correction
7. Notes: "Monthly audit, physical count 3 less than system"
8. System now matches reality
```

---

### Stock Refill Checklist

**Before Refilling:**
- [ ] Verified physical count matches delivery
- [ ] Checked invoice/packing slip
- [ ] Inspected items for damage
- [ ] Identified correct variant in system

**During Refilling:**
- [ ] Selected correct reason code
- [ ] Added supplier/invoice details in notes
- [ ] Verified quantity change is positive
- [ ] Saved adjustment

**After Refilling:**
- [ ] Verified new stock shows correctly
- [ ] Checked status changed to "In Stock"
- [ ] Confirmed product visible on storefront
- [ ] Filed physical paperwork

---

## Order Management

### Order Status Flow

```
Draft → Confirmed → Processing → Shipped → Delivered
                    ↓
                Cancelled (any stage before delivered)
```

**Status Definitions:**
- **Draft** - Cart saved, not yet placed
- **Pending** - Order placed, awaiting confirmation
- **Confirmed** - Order accepted, payment received
- **Processing** - Being prepared for shipment
- **Shipped** - Dispatched to customer
- **Delivered** - Received by customer
- **Cancelled** - Order cancelled (refund processed if paid)

### Viewing Orders

Navigate to **Orders** to see:
- **All Orders** - Complete list
- **Pending** - Awaiting confirmation
- **Confirmed** - Ready to process
- **Shipped** - In transit
- **Delivered** - Completed
- **Cancelled** - Cancelled orders

**Columns Displayed:**
- Order Number (e.g., ORD-12345)
- Date Placed
- Customer Name
- Items Count
- Total Amount
- Payment Status (Pending/Paid/Failed/Refunded)
- Order Status
- Actions

### Processing an Order

1. **Click Order Number** to view details
2. **Review Order:**
   - Customer shipping address
   - Items ordered (vendor products highlighted)
   - Payment status
   - Special instructions

3. **Update Status:**
   - **Confirm Order** - Accept the order
   - **Process Order** - Start preparing shipment
   - **Ship Order** - Mark as dispatched (add tracking info)
   - **Mark Delivered** - Confirm customer received it
   - **Cancel Order** - Cancel with reason (triggers refund if paid)

4. **Add Tracking Information** (when shipping):
   - Courier name
   - Tracking number
   - Tracking URL

### Order Details Page

Shows comprehensive information:
- **Order Timeline** - Status history with timestamps
- **Items** - Product, variant, quantity, price per item
- **Payment Info** - Method, status, transaction ID
- **Shipping Address** - Customer's delivery address
- **Order Summary** - Subtotal, shipping, discount, total
- **Internal Notes** - Add private notes about the order

### Handling Refunds

When order is cancelled or customer requests refund:

1. Open the order
2. Click **"Initiate Refund"**
3. Select refund method (full/partial)
4. Add refund reason
5. System processes refund via payment gateway
6. Track refund status on order page

### Order Invoices

**Download PDF Invoices:**
- **Customer Invoice** - For customer (download_customer_invoice)
- **Vendor Invoice** - For vendor internal use (download_vendor_invoice)

### Draft Orders

Admin-only feature to create orders manually:

1. Navigate to **Orders → Draft Orders**
2. Click **"New Draft Order"**
3. Add customer and items
4. Apply discounts if needed
5. **Convert to Order** - Send to customer for payment
   OR **Mark as Paid** - If payment received offline

### Vendor-Specific Order Views

**Vendors see:**
- Only orders containing their products
- Vendor commission calculations
- Only their items in multi-vendor orders
- Customer name but not full details

**Admins see:**
- All orders with all items
- Platform fees and calculations
- Complete customer information
- All vendor earnings per order

---

## Admin: SALES

This section covers advanced sales management features available to administrators.

### Checkout Sessions

**What are Checkout Sessions?**

Checkout sessions track the entire payment process from cart to completion. Each time a customer initiates checkout, a session is created to monitor:
- Payment attempts
- Success/failure status
- Multiple orders (in multi-vendor scenarios)
- Refunds and partial refunds

**Accessing Checkout Sessions:**

Navigate to **Orders → Checkout Sessions** (or Sales → Checkout Sessions)

**Dashboard Overview:**

The checkout sessions page shows four key metrics:

| Metric | Description | Indicator |
|--------|-------------|-----------|
| **Total Sessions** | All checkout attempts | Blue border |
| **Successful** | Completed payments | Green border |
| **Failed** | Payment failures | Red border |
| **Pending** | Awaiting payment | Amber border |

**Session Status Types:**

- **Paid** - Payment completed successfully
- **Failed** - Payment declined or error occurred
- **Pending** - Customer in checkout, not completed
- **Refunded** - Full refund processed
- **Partially Refunded** - Partial refund processed

**Session Details View:**

Click any session ID to see:
- **Session Information** - ID, created time, status
- **Customer** - Email, guest or registered
- **Orders** - All orders in this session (multi-vendor)
- **Payment Details** - Method, amount, transaction ID
- **Payment Logs** - Step-by-step payment flow
- **Analytics** - Vendor breakdown, order status distribution

**Using Checkout Sessions:**

1. **Track Conversion Rate:**
   - See what percentage of sessions complete payment
   - Identify if customers are abandoning checkout

2. **Debug Payment Issues:**
   - Find failed sessions
   - View payment logs for error details
   - See exact failure reason

3. **Monitor Multi-Vendor Orders:**
   - One checkout can create multiple orders (one per vendor)
   - See all related orders in one view
   - Track which vendor orders are paid/refunded

4. **Filter and Search:**
   - **By Status:** Paid, Failed, Pending, Refunded
   - **By Payment Method:** Razorpay, Cash on Delivery
   - **By Date Range:** Custom date selection
   - **Search:** Session ID or customer email

**Common Actions:**

- **View Analytics** - Click "Analytics" to see detailed breakdown
- **Download Report** - Export data for analysis
- **Investigate Failures** - Filter by "Failed" to troubleshoot

---

### Refunds

**Understanding the Refund Process:**

Refunds return money to customers for cancelled or returned orders. The system supports full and partial refunds.

**When to Process Refunds:**

✅ **Process Refund When:**
- Customer cancels order before shipment
- Order is damaged/lost in transit
- Customer returns item (after receiving)
- Wrong item shipped
- Price adjustment needed

❌ **Don't Process Refund When:**
- Order already delivered and customer happy
- Just changing shipping address (edit order instead)
- Item out of stock (cancel order instead)

**How to Process a Refund:**

**Method 1: From Order Details**

1. **Navigate to Orders**
2. **Find the order** (use search or filter)
3. **Click Order Number** to open details
4. **Review Order Status:**
   - Must be "Confirmed", "Processing", or "Shipped"
   - Payment status must be "Paid"

5. **Click "Initiate Refund"** button
6. **Select Refund Type:**
   - **Full Refund** - Return entire amount
   - **Partial Refund** - Return portion (specify amount)

7. **Specify Reason:**
   - Customer cancellation
   - Damaged goods
   - Wrong item
   - Price adjustment
   - Other (specify)

8. **Add Notes** (optional but recommended)
   - Customer communication details
   - Internal reference numbers
   - Approval manager name

9. **Click "Process Refund"**

**What Happens Next:**

- System sends refund request to payment gateway
- Refund status changes to "Processing"
- Customer receives refund in 5-7 business days (depending on bank)
- Order status changes to "Refunded" or "Partially Refunded"
- Stock is NOT automatically restored (manual adjustment needed)

**Tracking Refunds:**

1. **Go to Orders → Refunds** (or filter by status)
2. **View all refund requests:**
   - Order number
   - Customer name
   - Refund amount
   - Status (Pending/Processing/Completed/Failed)
   - Request date
   - Refund reference ID

3. **Refund Status Meanings:**
   - **Pending** - Awaiting admin approval
   - **Processing** - Sent to payment gateway
   - **Completed** - Money returned to customer
   - **Failed** - Refund error (contact support)

**Partial Refunds:**

**When to Use:**
- Customer keeps item but price adjustment needed
- Shipping refund only
- One item from multi-item order

**How to Process:**
1. Same steps as full refund
2. Select "Partial Refund"
3. Enter specific amount
4. Must be less than or equal to order total
5. Add explanation in notes

**Refund Reports:**

**View Refund Analytics:**
- Total refunds this month
- Refund rate (refunds ÷ total orders)
- Average refund amount
- Reasons breakdown
- Trends over time

**Export Refund Data:**
1. Filter orders by "Refunded" status
2. Click "Export CSV"
3. Use for accounting and reconciliation

**Important Notes:**

⚠️ **Stock Management:**
- Refunding does NOT automatically return stock
- If customer returns physical item, manually adjust stock
- Use "Return" reason in stock adjustment

⚠️ **Vendor Earnings:**
- Refunded orders are deducted from vendor payouts
- Vendor sees refund in their earnings report
- Commission fees are also reversed

⚠️ **Timing:**
- Refunds take 5-7 business days to appear in customer account
- Razorpay/card refunds may take longer than UPI
- Failed refunds must be retried manually

---

### Draft Orders

**What are Draft Orders?**

Draft orders are unpaid orders created by administrators. Useful for:
- Phone orders from customers
- Wholesale/bulk orders
- Custom quotes
- Orders needing approval before payment
- Replacing failed online orders

**Access:** Admin Only (Orders → Draft Orders)

**Draft Order Lifecycle:**

```
Create Draft → Add Items/Customer → Send to Customer/Payment → Convert to Order
```

**Creating a Draft Order:**

1. **Navigate to Orders → Draft Orders**
2. **Click "New Draft Order"**
3. **Select Customer:**
   - Search existing customers
   - Or create new customer on-the-fly
   - Can be left blank for guest orders

4. **Add Order Items:**
   - **Search Products** - Type to find by name/SKU
   - **Select Variant** - Choose specific size/color
   - **Enter Quantity** - Number of units
   - **Set Price** - Can override default price
   - **Add More Items** - Click "+ Add Item" for multiple

5. **Apply Discounts (Optional):**
   - Select coupon from dropdown
   - Or enter custom discount amount
   - Add discount reason

6. **Add Shipping Address:**
   - Select from customer's saved addresses
   - Or enter new address manually
   - Calculate shipping cost

7. **Add Notes:**
   - **Customer Notes** - Visible to customer (delivery instructions)
   - **Admin Notes** - Internal only (approval notes, special handling)

8. **Save Draft Order**

**Managing Draft Orders:**

**Draft Order List View:**
- All drafts with status
- Customer name (if assigned)
- Item count
- Total amount
- Created date
- Actions available

**Actions on Draft Orders:**

| Action | When to Use | Result |
|--------|-------------|--------|
| **Edit** | Change items, prices, quantity | Updates draft |
| **Send to Customer** | Customer needs to pay online | Email with payment link |
| **Mark as Paid** | Received cash/cheque/offline payment | Converts to regular order |
| **Convert to Order** | Customer ready to complete | Becomes regular order |
| **Delete** | Order not needed | Removes draft |

**Converting Draft to Order:**

**Method 1: Send Payment Link (Customer Pays Online)**

1. Open draft order
2. Click **"Send Invoice"** or **"Send Payment Link"**
3. System emails customer with secure payment link
4. Customer clicks link → Goes to checkout → Pays
5. Draft automatically converts to order on payment

**Method 2: Mark as Paid (Offline Payment)**

1. Open draft order
2. Click **"Mark as Paid"**
3. Select payment method:
   - Cash
   - Cheque
   - Bank Transfer
   - Other
4. Enter reference number (cheque #, transaction ID)
5. Add notes about payment receipt
6. Click **"Confirm Payment"**
7. Draft becomes confirmed order immediately

**Method 3: Direct Conversion (For Record Keeping)**

1. Open draft order
2. Click **"Convert to Order"**
3. Order created in "Pending" status
4. Manually update payment status as needed

**Use Cases for Draft Orders:**

**Case 1: Phone Order**
```
Customer calls to order:
1. Create draft order
2. Add items customer wants
3. Enter customer details
4. Save draft
5. Click "Send Payment Link"
6. Customer receives email and pays
7. Order confirmed automatically
```

**Case 2: Wholesale Quote**
```
Business customer wants bulk pricing:
1. Create draft order
2. Add all items with custom prices
3. Add admin notes: "Wholesale pricing approved by manager"
4. Save draft
5. Send to customer for review
6. Customer approves and pays, or requests changes
```

**Case 3: Replacement Order**
```
Customer's order had damaged item:
1. Find original order
2. Create draft order
3. Add replacement item
4. Price: ₹0 (free replacement)
5. Mark as paid with note: "Replacement for Order #12345"
6. Ship replacement
```

**Draft Order Best Practices:**

✅ **DO:**
- Add clear admin notes explaining the draft
- Use for custom pricing situations
- Send payment links promptly
- Delete abandoned drafts after 30 days
- Include shipping costs in total

❌ **DON'T:**
- Leave drafts unactioned for weeks
- Create drafts without customer knowledge
- Forget to mark as paid for cash orders
- Mix wholesale and retail in same draft

---

## PLATFORM: Vendor Payouts

**Overview:**

Vendor payouts transfer earnings from the platform to vendors. This section covers both vendor self-service requests and admin processing.

### Understanding Vendor Earnings

**Revenue Flow:**

```
Customer Pays → Platform Receives → Fees Deducted → Vendor Earns → Payout Transferred
```

**Fee Breakdown:**

| Fee Type | Description | Who Pays |
|----------|-------------|----------|
| **Platform Fee** | Commission on sale (e.g., 10%) | Vendor |
| **Gateway Fee** | Payment processing (e.g., 2%) | Vendor |
| **Gateway GST** | Tax on gateway fee | Vendor |
| **Net Payout** | Vendor's final earnings | Vendor receives |

**Example Calculation:**

```
Order Total: ₹1,000
Platform Fee (10%): ₹100
Gateway Fee (2%): ₹20
Gateway GST (18% of ₹20): ₹3.60
Total Fees: ₹123.60
Net Vendor Earnings: ₹876.40
```

---

### For Vendors: Requesting Payouts

**When Can Vendors Request Payout?**

✅ **Requirements:**
- Order status: **Delivered**
- Payment status: **Paid**
- Payout status: **Available** (not already requested)
- Minimum amount: Platform configured (e.g., ₹500)
- No pending payout requests

❌ **Cannot Request When:**
- Order pending, processing, or shipped
- Order not yet paid
- Payout already requested for order
- Current request pending
- Below minimum threshold

**Requesting a Payout (Vendor View):**

1. **Navigate to Earnings** (or Vendor Dashboard)
2. **Review Available Balance**
   - Total earnings to date
   - Available for payout (delivered + paid orders)
   - Pending earnings (orders not yet delivered)
   - Already paid out total

3. **Click "Request Payout"**
4. **Select Orders to Include:**
   - Checkbox next to each eligible order
   - Or click "Select All"
   - See real-time total calculation

5. **Review Summary:**
   - Total Amount (gross)
   - Platform Fees
   - Gateway Fees + GST
   - **Net Payout** (what vendor receives)

6. **Verify Bank Details**
   - Account holder name
   - Bank name
   - Account number (last 4 digits shown)
   - IFSC code
   - Update if needed before submitting

7. **Submit Request**
8. **Confirmation:** Request submitted, awaiting admin approval

**After Submission:**

**Track Status:**
- **Pending** - Awaiting admin review
- **Approved** - Authorized, not yet transferred
- **Paid** - Funds transferred to bank
- **Rejected** - Returned to available balance (see reason)

**View Payout History:**
1. Go to **Earnings → Payouts**
2. See all past payouts:
   - Date requested
   - Amount
   - Status
   - Orders included
   - Transaction reference (when paid)

---

### For Admins: Processing Payouts

**Access:** Navigate to **Payouts** (or Admin → Payouts)

**Dashboard Overview:**

**Stats Cards:**
- **Pending Requests** - Count and total amount
- **Approved (Unpaid)** - Ready for bank transfer
- **Paid This Month** - Total transferred
- **Average Processing Time** - How long requests take

**Processing Workflows:**

**Workflow 1: Approve and Pay (Same Day)**

```
1. Payouts → Filter by "Pending"
2. Review payout details:
   - Vendor name and bank details
   - Orders included (verify delivered + paid)
   - Amount breakdown
   - Check for any issues
3. Click "Approve"
   - Optional: Add approval notes
4. Payout moves to "Approved" status
5. Make actual bank transfer (outside system)
6. Return to Payouts page
7. Click "Mark as Paid"
8. Enter:
   - Transaction reference number (from bank)
   - Payment date
   - Notes about transfer
9. Vendor notified automatically
```

**Workflow 2: Bulk Processing (Weekly)**

```
1. Every Friday: Review all pending payouts
2. Select multiple payouts (checkbox)
3. Click "Approve Selected"
4. Generate bank file for bulk transfer
5. Upload to corporate banking portal
6. After transfer completes:
   - Mark each as paid
   - Or use "Bulk Mark Paid" with CSV upload
```

**Payout Status Actions:**

| Status | Action | Who | Result |
|--------|--------|-----|--------|
| **Pending** | Approve | Admin | Moves to Approved |
| **Pending** | Reject | Admin | Returns to vendor balance |
| **Approved** | Mark Paid | Admin | Vendor receives money |
| **Approved** | Cancel | Admin | Returns to Pending |
| **Any** | View Details | Both | See orders, amounts, history |

**Rejecting a Payout:**

**When to Reject:**
- Bank details incorrect
- Fraud suspicion
- Order dispute ongoing
- Duplicate request
- Vendor account issues

**How to Reject:**
1. Open payout details
2. Click **"Reject"**
3. **Select Reason:**
   - Incorrect bank details
   - Pending order dispute
   - Duplicate request
   - Account verification needed
   - Other (specify)
4. **Add Detailed Explanation**
   - Clear reason for vendor understanding
   - Steps to resolve (if applicable)
   - Contact information for questions
5. **Confirm Rejection**

**What Happens:**
- Vendor receives notification with rejection reason
- Orders return to "Available for Payout" status
- Vendor can correct issues and re-request
- Record kept for audit

---

### Payout Configuration

**Setting Payout Rules (Admin):**

**Minimum Payout Amount:**
- Default: ₹500
- Purpose: Reduce transaction fees for small amounts
- Can be changed in Platform Settings

**Maximum Payout Amount:**
- Default: ₹100,000
- Purpose: Risk management for large transfers
- Can be increased for trusted vendors

**Automatic Payout Schedule:**
- Weekly (every Friday)
- Bi-weekly (1st and 15th)
- Monthly (1st of month)
- Manual only (vendors must request)

**To Configure:**
1. Navigate to **Settings → Platform Settings**
2. Find "Vendor Payout Configuration"
3. Set minimum, maximum, schedule
4. Save changes
5. Vendors see new rules immediately

---

### Payout Reports & Analytics

**Available Reports:**

**1. Pending Payouts Report**
- All pending requests
- Vendor details
- Amounts
- Days pending (aging)
- Export for approval workflow

**2. Payout History by Vendor**
- All payouts for specific vendor
- Date, amount, status
- Orders included in each
- YTD totals

**3. Monthly Payout Summary**
- Total paid out this month
- Number of vendors paid
- Average payout amount
- Comparison to previous month

**4. Outstanding Balances**
- Vendors with unclaimed earnings
- Available but not requested
- Escheat reporting (unused funds)

**Exporting Data:**

1. Go to Payouts page
2. Apply filters as needed
3. Click **"Export CSV"** or **"Export Excel"**
4. Use for:
   - Accounting reconciliation
   - Tax reporting
   - Bank reconciliation
   - Vendor statements

---

### Best Practices

**For Vendors:**

✅ **DO:**
- Request payouts weekly or bi-weekly
- Keep bank details updated
- Check earnings dashboard regularly
- Request before large amounts accumulate
- Verify all orders are delivered before requesting

❌ **DON'T:**
- Request daily (creates admin overhead)
- Let earnings accumulate for months
- Ignore bank detail verification emails
- Request for undelivered orders

**For Admins:**

✅ **DO:**
- Process payouts within 3 business days
- Verify bank details for new vendors
- Communicate rejection reasons clearly
- Use consistent processing schedule
- Keep payout records for 7 years

❌ **DON'T:**
- Delay processing without communication
- Approve suspicious large requests without verification
- Forget to mark as paid after transfer
- Ignore bank bounce-backs

---

### Troubleshooting Payouts

**Issue: Payout stuck in "Pending"**

**Check:**
- Admin has not reviewed yet
- Vendor is new (needs verification)
- Large amount (requires manual approval)
- Weekend/holiday (processed next business day)

**Solution:**
- Wait 3 business days
- Contact admin if urgent
- Check email for verification requests

---

**Issue: "Cannot request payout - no orders available"**

**Check:**
- Orders not yet delivered
- Orders not yet paid by customer
- Payout already requested for orders
- Orders under dispute

**Solution:**
- Wait for delivery confirmation
- Check payment status on orders
- Review previous payout history
- Resolve any open disputes

---

**Issue: Bank transfer failed/bounced**

**Check:**
- Incorrect account number
- Closed bank account
- IFSC code changed
- Vendor name mismatch

**Solution:**
1. Contact vendor for correct details
2. Reject payout with "Invalid bank details" reason
3. Vendor updates profile with correct info
4. Vendor re-requests payout
5. Process normally

---

**Issue: Dispute about payout amount**

**Resolution Steps:**
1. Open payout details
2. Click "View Orders"
3. Verify each order:
   - Delivered? ✓
   - Paid? ✓
   - Correct commission rate? ✓
4. Check fee calculations
5. Provide vendor with detailed breakdown
6. If error found: Process adjustment payout

---

## MANAGEMENT: HSN Codes

**What are HSN Codes?**

HSN (Harmonized System of Nomenclature) codes are standardized product classification codes used for GST (Goods and Services Tax) in India. Each product category has a specific HSN code and associated GST rate.

**Why HSN Codes Matter:**
- **Tax Compliance** - Required for GST invoices
- **Accurate Tax Calculation** - Different rates for different products
- **Reporting** - Government reporting requirements
- **Legal Compliance** - Mandatory for businesses above turnover threshold

**Access:** Navigate to **HSN Codes** (Admin → HSN Codes)

---

### HSN Code Structure

**Code Format:**
- **2-digit** - Chapter (broad category)
- **4-digit** - Heading (product group)
- **6-digit** - Subheading (specific product)
- **8-digit** - India-specific extension

**Examples:**
```
Chapter 71: Natural or Cultured Pearls, Precious Stones
  ↳ 7113: Articles of jewellery and parts thereof
    ↳ 711319: Of precious metal
      ↳ 71131910: Gold jewellery
      ↳ 71131920: Silver jewellery
```

---

### Managing HSN Codes

**Viewing All HSN Codes:**

1. Navigate to **HSN Codes**
2. See list with:
   - Code number
   - Description
   - GST Rate (%)
   - Category name
   - Status (Active/Inactive)

3. **Search/Filter:**
   - Search by code number
   - Search by description
   - Filter by GST rate
   - Filter by status

**Adding New HSN Code:**

1. Click **"New HSN Code"**
2. Fill form:
   - **Code** (required) - The HSN number (e.g., "71131910")
   - **Description** (required) - Product description (e.g., "Gold jewellery")
   - **GST Rate** (required) - Tax percentage (e.g., 3, 5, 12, 18, 28)
   - **Category Name** (optional) - Grouping category
   - **Active** (checkbox) - Enable/disable

3. Click **"Create HSN Code"**

**Important:**
- Code must be unique
- GST rate should be current government rate
- Verify code accuracy with GST portal

---

**Editing HSN Codes:**

1. Find code in list
2. Click **"Edit"**
3. Modify fields as needed
4. Click **"Update HSN Code"**

**When to Edit:**
- GST rate changes (government notification)
- Description needs clarification
- Reassignment to different category
- Activate/deactivate

**⚠️ Warning:** Editing affects ALL products using this code. Existing orders keep original rate, new orders use new rate.

---

**Deactivating HSN Codes:**

**When to Deactivate:**
- Code no longer used
- Replaced by different code
- Temporary suspension

**How:**
1. Find code in list
2. Click **"Disable"** (or toggle Active checkbox)
3. Code becomes inactive

**Effect:**
- Cannot assign to new products
- Existing products keep code (for historical orders)
- Can reactivate later if needed

---

### Assigning HSN Codes to Products

**During Product Creation:**

1. Create/Edit product
2. Find **"HSN Code"** field
3. Dropdown shows active HSN codes
4. Format: "Code - Description (GST%)"
5. Select appropriate code
6. Save product

**Example Selection:**
```
☑️ 71131910 - Gold jewellery (3%)
   71131920 - Silver jewellery (3%)
   711711 - Imitation jewellery (12%)
   [Select...]
```

**Bulk Assignment:**

For multiple products:
1. Products → Select multiple (checkbox)
2. **Bulk Actions** → "Change HSN Code"
3. Select new HSN code
4. Apply to all selected products

---

### HSN Code Best Practices

✅ **DO:**
- Use government-verified HSN codes
- Keep rates updated with GST changes
- Assign specific codes (6-8 digit) not broad chapters
- Train team on code selection
- Audit product assignments quarterly
- Deactivate obsolete codes

❌ **DON'T:**
- Use approximate/closest codes
- Assign same code to very different products
- Ignore government GST rate changes
- Leave products without HSN codes
- Use inactive codes

---

### Common HSN Codes for E-commerce

| Category | Common Codes | GST Rate |
|----------|--------------|----------|
| **Jewelry** | 7113, 711319 | 3% |
| **Clothing** | 6101-6114, 6201-6214 | 5%, 12% |
| **Electronics** | 8517, 8528 | 18%, 28% |
| **Books** | 4901 | 0% |
| **Cosmetics** | 3303, 3304 | 18%, 28% |
| **Furniture** | 9403 | 12%, 18% |
| **Food Items** | Various | 0%, 5%, 12% |

**Note:** Always verify current rates from official GST portal as they change periodically.

---

### HSN Code Reports

**Available Reports:**

**1. Products by HSN Code**
- All products using specific code
- Inventory value
- Sales volume
- GST liability calculation

**2. GST Liability Report**
- Taxable amount by HSN code
- GST collected
- Input tax credit
- Net GST payable

**3. HSN Code Summary**
- Active codes count
- Products per code
- Revenue per code
- GST rate distribution

**Export for GSTR-1 Filing:**

1. Reports → GST Reports
2. Select period (monthly)
3. Generate HSN-wise summary
4. Export in government format
5. Upload to GST portal

---

### Troubleshooting HSN Codes

**Issue: "HSN Code not found"**

**Cause:** Code not in system or inactive

**Solution:**
1. Check if code exists (search by partial number)
2. If inactive: Activate it
3. If missing: Add new HSN code
4. Contact tax consultant if unsure of correct code

---

**Issue: Wrong GST rate on invoice**

**Cause:** Outdated HSN code rate

**Solution:**
1. Check government notification for rate change
2. Update HSN code with new rate
3. New orders will use correct rate
4. Existing orders keep original rate (correct)

---

**Issue: Product missing HSN code**

**Solution:**
1. Edit product
2. Select appropriate HSN code from dropdown
3. Save product
4. Product now GST compliant

---

**Issue: Uncertain which code to use**

**Decision Process:**
1. Check product material/composition
2. Identify primary use/purpose
3. Search HSN database by keywords
4. Compare descriptions
5. When in doubt: Use more specific code (longer digits)
6. Consult tax professional for high-value products

---

## Vendor Management (Admin Only)

### Creating a New Vendor

1. Navigate to **Vendors → New Vendor**
2. Fill in details:
   - **Business Name** - Company name
   - **Email** - Login credentials
   - **Password** - Initial password
   - **Phone** - Contact number
   - **Address** - Business address
   - **GST Number** - Tax identification
   - **Bank Details** - For payouts
3. Set **Active** status
4. Click **"Create Vendor"**

### Managing Vendors

**Vendor List View:**
- **Active Vendors** - Currently selling
- **Inactive Vendors** - Suspended or onboarding
- Search by name or email
- Quick view of product count and total sales

**Vendor Actions:**
- **Edit** - Update business info, bank details
- **Toggle Status** - Enable/disable vendor account
- **Act As** - Impersonate vendor to see their dashboard
- **View Products** - See all vendor's products
- **View Orders** - See orders with vendor's products
- **View Earnings** - Commission and payout history

### Impersonating Vendors

**To see vendor's perspective:**
1. Click **"Act As"** on vendor row
2. You're now viewing as that vendor
3. See restricted menu and filtered data
4. **Exit Vendor Mode** - Click "Exit" in header to return to admin view

**Use Cases:**
- Troubleshoot vendor issues
- Help vendors with product setup
- Verify vendor-only features work correctly
- Review vendor's earnings and orders

### Vendor Payouts

**View Pending Payouts:**
1. Navigate to **Payouts**
2. See list of vendor withdrawal requests
3. Columns: Vendor, Amount, Request Date, Status

**Processing Payouts:**
1. Click **"View"** on payout request
2. Verify vendor bank details
3. **Approve** - Authorize the payout
4. **Mark as Paid** - After transferring funds
5. **Reject** - If there's an issue (with reason)

**Vendor Earnings Report:**
- Total earnings per vendor
- Commission breakdown
- Payout history
- Pending amount

---

## Reports & Analytics

### Available Reports (Admin Only)

#### 1. Sales Report
**Path:** Reports → Sales
- **Date Range:** Select period (Today, Week, Month, Custom)
- **Metrics:**
  - Total Orders
  - Total Revenue
  - Average Order Value
  - Revenue by Date (chart)
  - Top Selling Products
  - Sales by Category

#### 2. Products Report
**Path:** Reports → Products
- **Best Sellers** - Top products by revenue
- **Low Performers** - Products with no sales
- **Stock Alerts** - Low/out of stock items
- **Category Performance** - Sales by category

#### 3. Customers Report
**Path:** Reports → Customers
- **New Customers** - Signups by date
- **Top Customers** - By order count and value
- **Customer Retention** - Repeat purchase rate
- **Geographic Distribution** - Orders by location

### Dashboard Analytics

**Real-time Metrics:**
- Orders today/this week/this month
- Revenue today/this week/this month
- Comparison to previous period
- Low stock alerts
- Pending orders count

### Exporting Data

Most reports support CSV export:
1. Apply filters as needed
2. Click **"Download CSV"** button
3. Open in Excel/Google Sheets for further analysis

### Vendor-Specific Reports

Vendors can access:
- **My Orders** - Only their product orders
- **My Earnings** - Commission calculations
- **My Products Performance** - Sales of their products
- **Inventory Report** - Their stock levels

---

## Support Tickets

### Creating a Support Ticket (Vendors)

1. Navigate to **Support Tickets**
2. Click **"New Ticket"**
3. Fill in:
   - **Subject** - Brief issue description
   - **Category** - Order Issue, Product, Payment, Technical, Other
   - **Priority** - Low, Medium, High, Urgent
   - **Message** - Detailed description
4. Attach files if needed (screenshots, invoices)
5. Click **"Create Ticket"**

### Managing Tickets

**Ticket Status:**
- **Open** - Awaiting response
- **Resolved** - Issue fixed
- **Closed** - No longer active

**Ticket Actions:**
- **Reply** - Add message to conversation
- **Resolve** - Mark as fixed
- **Close** - Close without resolving
- **Reopen** - Reopen resolved/closed ticket

### Viewing Your Tickets

**For Vendors:**
- See only tickets you created
- Response history with timestamps
- Admin replies highlighted

**For Admins:**
- See all tickets from all vendors
- Filter by: Status, Priority, Category, Vendor
- Assign tickets to team members (future feature)

### Ticket Best Practices

✅ **DO:**
- Be specific in subject line
- Include order numbers if relevant
- Attach screenshots for UI issues
- Respond promptly to admin questions
- Mark resolved when issue is fixed

❌ **DON'T:**
- Create multiple tickets for same issue
- Mark urgent unless truly critical
- Include sensitive data (passwords, full card numbers)

---

## Common Workflows

### Workflow 1: Adding a New Product (Vendor)

```
1. Products → New Product
2. Fill basic info (name, category, description)
3. Select category (shows relevant attributes)
4. Fill category-specific attributes
5. Create first variant:
   - Set Selling Price (₹1000)
   - Set MRP (₹1200) - Must be ≥ Selling Price
   - Set Stock Quantity (50)
   - Enable Track Inventory
   - Set Reorder Point (10)
   - Upload variant image
6. Upload product images (up to 15)
7. Set Active = true
8. Click Create Product
9. Verify product appears on storefront
```

### Workflow 2: Processing Daily Orders

```
1. Dashboard → Check "Pending Orders" count
2. Orders → Filter by "Pending"
3. For each order:
   a. Open order details
   b. Verify items and shipping address
   c. Click "Confirm Order"
   d. Prepare items for shipment
   e. Click "Process Order" (when ready to ship)
   f. Pack and ship items
   g. Click "Ship Order" (add tracking number)
   h. Update tracking when delivered
   i. Click "Mark Delivered"
```

### Workflow 3: Managing Low Stock

```
1. Dashboard → Check "Low Stock" or "Needs Reorder" alert
2. Inventory → Filter by "Needs Reorder"
3. Review items needing restock
4. Either:
   Option A - Bulk Restock:
   a. Click "Bulk Restock"
   b. Adjust quantities as needed
   c. Click "Restock Selected Items"
   
   Option B - Single Adjustments:
   a. Click "Adjust" on each item
   b. Enter quantity received
   c. Select "Restock" reason
   d. Add supplier invoice number in notes
5. Verify stock updated in product list
```

### Workflow 4: Handling Customer Return

```
1. Customer contacts support about return
2. Create Support Ticket (if not exists)
3. Agree on return terms
4. When item received back:
   a. Navigate to original order
   b. Click "Initiate Refund"
   c. Select full or partial refund
   d. Add reason: "Customer Return"
   e. Process refund
5. Restock item if sellable:
   a. Inventory → Find variant
   b. Click "Adjust"
   c. Enter positive quantity
   d. Reason: "Return"
6. Close support ticket
```

### Workflow 5: Monthly Payout Request (Vendor)

```
1. Earnings → View current balance
2. Ensure minimum payout threshold met
3. Click "Request Payout"
4. Enter amount to withdraw
5. Verify bank details are correct
6. Submit request
7. Wait for admin approval (1-3 business days)
8. Check Payouts page for status:
   - Pending: Awaiting approval
   - Approved: Authorized, not yet transferred
   - Paid: Funds transferred
```

### Workflow 6: Admin Reviewing Vendor Performance

```
1. Vendors → Select vendor
2. Click "Act As" to see vendor's view
3. Check Dashboard metrics:
   - Total orders this month
   - Revenue generated
   - Low stock items
   - Open tickets
4. Navigate to Products → Review catalog
5. Check Orders → Verify fulfillment speed
6. Check Reviews → See customer feedback
7. Check Support Tickets → Response quality
8. Exit Vendor Mode
9. Process pending payout if appropriate
```

---

## Troubleshooting

### Common Issues & Solutions

#### Issue: Product not appearing on storefront
**Check:**
- ☑️ Product status is "Active"
- ☑️ At least one variant is "Active"
- ☑️ Variant has stock_quantity > 0
- ☑️ Product has at least one image
- ☑️ Category is not deleted
- ☑️ Vendor is active (if applicable)

**Solution:** Edit product and verify all above

---

#### Issue: Can't save product (validation errors)
**Common Errors:**
- "MRP cannot be less than selling price" - Increase MRP or decrease selling price
- "Name can't be blank" - Fill required fields
- "SKU already taken" - Leave blank for auto-generation

**Solution:** Check error messages at top of form, fix highlighted fields

---

#### Issue: Order stuck in "Pending"
**Possible Causes:**
- Payment not completed by customer
- Payment gateway error
- Stock unavailable (but system should prevent this)

**Solution:**
1. Check payment status on order details
2. Contact customer if payment issue
3. If stock issue, adjust inventory and reconfirm

---

#### Issue: Stock quantity wrong after order
**Cause:** Manual edits bypassed adjustment tracking

**Solution:**
1. Don't manually edit stock_quantity field
2. Always use Inventory → Adjust
3. Check Adjustment History for discrepancies

---

#### Issue: Vendor can't see their products
**Cause:** Product assigned to wrong vendor or admin not in vendor context

**Solution:**
1. Admin: Check product's vendor_id in database
2. Vendor: Ensure logged in with correct credentials
3. Admin: Use "Act As" to verify vendor view

---

#### Issue: Can't process payout
**Causes:**
- Insufficient balance
- Bank details not verified
- Vendor account inactive

**Solution:**
1. Check vendor has available earnings
2. Verify bank account details in vendor profile
3. Ensure vendor status is "Active"

---

#### Issue: Images not uploading
**Checks:**
- File size < 2MB per image
- File type: JPG, PNG, GIF, WebP
- Stable internet connection
- Browser cache (try Ctrl+F5)

**Solution:** Compress images, verify format, retry upload

---

### Getting Help

**For Technical Issues:**
1. Check this manual first
2. Search existing Support Tickets
3. Create new ticket with:
   - Screenshot of error
   - Steps to reproduce
   - Browser and OS info

**For Business Questions:**
- Contact platform administrator
- Use "General" ticket category

**Emergency Contacts:**
- Critical payment issues: Support Ticket (Urgent priority)
- System down: Contact platform admin immediately

---

## Quick Reference Cards

### Product Creation Checklist
- [ ] Name filled
- [ ] Category selected
- [ ] Description added
- [ ] First variant created
- [ ] Selling price set
- [ ] MRP ≥ Selling price
- [ ] Stock quantity entered
- [ ] Track inventory enabled
- [ ] Reorder point set
- [ ] At least one image uploaded
- [ ] Active status checked

### Order Processing Checklist
- [ ] Order reviewed
- [ ] Items verified in stock
- [ ] Shipping address confirmed
- [ ] Order confirmed
- [ ] Items packed
- [ ] Tracking number added
- [ ] Order marked shipped
- [ ] Delivery confirmed

### Monthly Vendor Tasks
- [ ] Review low stock alerts
- [ ] Process bulk restock
- [ ] Check pending reviews
- [ ] Respond to support tickets
- [ ] Request payout (if eligible)
- [ ] Review sales performance

---

## Glossary

| Term | Definition |
|------|------------|
| **SKU** | Stock Keeping Unit - unique product identifier |
| **MRP** | Maximum Retail Price - crossed-out original price |
| **Variant** | Product variation (size, color, style) |
| **Reorder Point** | Stock level that triggers reorder alert |
| **Track Inventory** | Auto-deduct stock when orders placed |
| **Vendor Context** | Viewing data filtered to specific vendor |
| **Draft Order** | Unpaid order created by admin |
| **Payout** | Vendor withdrawal of earnings |
| **Commission** | Platform fee deducted from vendor sales |
| **HSN Code** | Harmonized System of Nomenclature - tax code |

---

**Document Version:** 1.0  
**Last Updated:** March 2026  
**For Questions:** Contact platform administrator
