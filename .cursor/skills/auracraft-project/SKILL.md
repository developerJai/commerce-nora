---
name: auracraft-project
description: Project context and architecture for the Noralooks jewellery e-commerce app (Rails 8.1, Tailwind, Hotwire). Use when making changes, adding features, debugging, or exploring this codebase to avoid re-analyzing the project structure.
---

# Noralooks (Auracraft) - Project Context

## Stack

| Layer | Tech |
|-------|------|
| Framework | Rails 8.1.2, Ruby 3.2.0 |
| DB | PostgreSQL (`noralooks_development`) |
| CSS | Tailwind CSS 4 via `tailwindcss-rails` gem |
| JS | Hotwire (Turbo + Stimulus), Importmap (no bundler) |
| Assets | Propshaft (not Sprockets) |
| Images | Active Storage — local (dev), AWS S3 (prod) |
| Auth | Custom `has_secure_password` + session — **no Devise** |
| Pagination | Pagy 43.x |
| Soft deletes | `SoftDeletable` concern (`deleted_at` + `default_scope`) |
| Deploy | Kamal + Docker + Thruster |

## Design System

- **Brand colors**: Rose (`rose-700`/`800`/`900`) primary, Stone grays neutral, Amber accents
- **Fonts**: `Playfair Display` (serif headings) + `Inter` (sans body) via Google Fonts
- **Patterns**: Rounded corners (`rounded-xl`/`2xl`), gradient backgrounds, rose-gold badges
- Storefront CSS: `app/assets/tailwind/application.css`

## Architecture

### Multi-Vendor Role-Based Access

The app supports two admin roles via the shared admin panel:

- **Admin** (`role: 'admin'`): Full access to all features — homepage, categories, vendors, HSN codes, reports, customers, coupons, draft orders
- **Vendor** (`role: 'vendor'`): Scoped access to own products, orders, inventory, reviews, and support tickets

Both roles authenticate as `AdminUser` records. Vendors log in at `/vendor/login`, admins at `/admin/login`. Both are redirected to the same `/admin` panel with role-filtered sidebar and data scoping.

**Admin impersonation**: Admin can "Act as Vendor" from the vendor show page, which sets `session[:acting_as_vendor_id]`. All data queries scope to that vendor until the admin exits vendor mode.

**Key helpers** (in `Admin::BaseController`):
- `current_vendor` — returns vendor context (vendor's own or admin impersonation)
- `admin_role?` / `vendor_role?` — check current user's role
- `vendor_context?` — true when data should be scoped to a vendor
- `vendor_scoped(scope)` — filters a scope by `vendor_id` when in vendor context
- `require_admin_role!` — before_action gate for admin-only controllers

### Storefront (root namespace)
- `ApplicationController` — base, session-based customer auth
- Routes: root `home#index`, `products#index/show`, `categories#show`, `cart`, `checkout`, `orders`, `wishlists`, `search`, `support_tickets`
- Layout: `app/views/layouts/application.html.erb` — sticky header, mobile bottom nav, full footer
- **No vendor info exposed** — customers never see vendor details

### Vendor Auth (`/vendor` namespace)
- `Vendor::SessionsController` — login/logout at `/vendor/login`, authenticates `AdminUser` with `role: 'vendor'`
- Uses `layout 'admin_auth'` with dynamic heading ("Vendor Portal" vs "Admin Panel")

### Admin (`/admin` namespace)
- `Admin::BaseController` — `layout 'admin'`, auth via `session[:admin_id]` → `AdminUser`, role-based authorization
- 20 controllers: Dashboard, Products, ProductVariants, Categories, Inventory, Banners, HomepageCollections, HomepageCollectionItems, Orders, DraftOrders, Coupons, Customers, Reviews, SupportTickets, Reports, Sessions, Settings, Passwords, **Vendors**, **HsnCodes**
- Layout: `app/views/layouts/admin.html.erb` — dark sidebar (`bg-slate-900`), indigo accent buttons, conditional sidebar links based on role, impersonation banner
- Sidebar link partial: `app/views/admin/shared/_sidebar_link.html.erb` (icon hash map with 'vendors' and 'hsn' icons)

**Admin-only controllers** (blocked for vendors with `require_admin_role!`):
Banners, HomepageCollections, HomepageCollectionItems, Categories, Customers, Coupons, DraftOrders, Reports, Vendors, HsnCodes

**Vendor-scoped controllers** (data filtered by `current_vendor`):
Dashboard, Products, ProductVariants, Orders, Inventory, Reviews, SupportTickets

### Models (23)

| Model | Key relationships |
|-------|-------------------|
| `Vendor` | has_many :admin_users, :products, :orders, :support_tickets; SoftDeletable |
| `HsnCode` | has_many :products; code + gst_rate for tax classification |
| `AdminUser` | has_secure_password; belongs_to :vendor (optional); role: 'admin' or 'vendor' |
| `Product` | belongs_to :vendor (optional), :category, :hsn_code (optional); has_many :variants, :reviews; has_many_attached :images |
| `ProductVariant` | belongs_to :product; has_one_attached :image; has stock/inventory fields |
| `Category` | self-referential tree (parent_id); scopes: `active`, `root`, `ordered` |
| `Banner` | has_one_attached :image; scopes: `visible` = active + current + ordered |
| `HomepageCollection` | has_many :items; layout_type: grid_4/grid_3/grid_2/bento/asymmetric |
| `HomepageCollectionItem` | belongs_to :homepage_collection; has_one_attached :image; overlay_position |
| `Customer` | has_secure_password; has_many :addresses, :orders, :reviews, :wishlists |
| `Order` | belongs_to :vendor (optional); lifecycle: pending -> confirmed -> processing -> shipped -> delivered; HSN-based tax; checkout_batch_id for split orders |
| `OrderItem` | belongs_to :vendor (optional); denormalized vendor_id for performance |
| `Cart` / `CartItem` | token-based; belongs_to customer (optional) |
| `Coupon` | percentage or fixed discount; usage tracking |
| `Review` | moderated (approved boolean); updates product average_rating |
| `SupportTicket` | belongs_to :customer (optional), :vendor (optional); for_vendor scope; vendor-to-admin tickets |
| `TicketMessage` | polymorphic sender (Customer or AdminUser) |

All models include `SoftDeletable` concern — `destroy` calls `soft_delete` (sets `deleted_at`).

### Order Splitting at Checkout

When a customer checks out, cart items are grouped by `product.vendor_id`. One order is created per vendor group:
- Shared `checkout_batch_id` links orders from same checkout
- Coupon discount distributed proportionally per vendor subtotal
- Shipping calculated independently per vendor order
- Tax calculated per item's HSN code rate (default 3% for jewellery)

### HSN-Based Tax Calculation

Tax is calculated per order item based on the product's `hsn_code.gst_rate`:
- `Order#calculate_hsn_tax(discounted_subtotal)` sums per-item tax, adjusts for discounts proportionally
- Default rate: 3% (jewellery standard) when no HSN code assigned
- Legacy `Order.calculate_tax_amount` (flat 18%) kept for backward compatibility
- Admin manages HSN codes at `/admin/hsn_codes`; vendors select when creating products

### Homepage (`HomeController#index`)

Loads and renders in order:
1. `@banners` — `Banner.visible.limit(5)` -> carousel
2. `@homepage_collections` — `HomepageCollection.visible` with items -> dynamic sections
3. `@categories` — Shop by Category grid
4. `@featured_products` — Bestsellers
5. Promotional banner (hardcoded)
6. `@new_arrivals` — New Arrivals
7. Why Choose Us (hardcoded)

Homepage is admin-only (vendors cannot manage banners, collections, or categories).

### Key Directories

```
app/controllers/admin/     — 20 admin controllers (includes Vendors, HsnCodes)
app/controllers/vendor/    — Vendor::SessionsController (login/logout)
app/views/admin/           — admin CRUD views
app/views/admin/vendors/   — vendor management views (index, show, new, edit, _form)
app/views/admin/hsn_codes/ — HSN code management views
app/views/vendor/sessions/ — vendor login view
app/views/home/            — homepage + collection partials
app/views/shared/          — _product_card, etc.
app/javascript/controllers/ — 22 Stimulus controllers
db/migrate/                — 30 migrations
lib/tasks/                 — rake tasks (seed:homepage, seed:hsn_codes, seed:vendors, seed:products, seed:orders)
```

### Conventions

- Admin forms: white card (`bg-white rounded-lg shadow-sm p-6`), indigo buttons, gray borders
- Storefront cards: `rounded-xl`/`2xl`, rose accents, serif headings, hover transitions
- Scopes: `active`, `ordered`, `visible` on most models; `for_vendor` on Order and SupportTicket
- SKU format: `PRODUCTSLUG-VARIANTINDEX` (uppercase, no hyphens)
- All image uploads via Active Storage `has_one_attached :image` or `has_many_attached :images`
- Admin toggle pattern: `toggle_status` action + `PATCH` route
- Vendor scoping: always use `vendor_scoped(scope)` helper or `for_vendor` model scope
- Security: vendor_id set server-side (never from form params for vendor role); `require_admin_role!` on admin-only controllers

### Credentials

- Admin: `admin@noralooks.com` / `password123`
- Vendor 1: `vendor1@noralooks.com` / `password123` (Laxmi Gold House)
- Vendor 2: `vendor2@noralooks.com` / `password123` (Shree Diamonds)
- Vendor 3: `vendor3@noralooks.com` / `password123` (Royal Gems & Jewels)
- Demo customer: `demo@example.com` / `password123`

## Rake Tasks

```bash
# Seed everything
rails db:seed

# Individual sections
rails seed:homepage    # Admin, categories, banners, homepage collections, coupons
rails seed:hsn_codes   # HSN codes for tax classification
rails seed:vendors     # Sample vendors with login credentials
rails seed:products    # Products, variants, inventory (VENDOR_ID=N to scope to specific vendor)
rails seed:orders      # Customers, addresses, reviews, demo orders
```
