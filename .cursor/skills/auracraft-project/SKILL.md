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
| Images | Active Storage — local (dev), AWS S3 + CloudFront CDN (prod); organized folder keys |
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

Two admin roles via the shared admin panel:

- **Admin** (`role: 'admin'`): Full access — homepage, categories, vendors, HSN codes, reports, customers, coupons, draft orders
- **Vendor** (`role: 'vendor'`): Scoped to own products, orders, inventory, reviews, support tickets

Both authenticate as `AdminUser`. Vendors at `/vendor/login`, admins at `/admin/login`. Same `/admin` panel with role-filtered sidebar.

**Admin impersonation**: "Act as Vendor" sets `session[:acting_as_vendor_id]`.

**Key helpers** (`Admin::BaseController`): `current_vendor`, `admin_role?`, `vendor_role?`, `vendor_context?`, `vendor_scoped(scope)`, `require_admin_role!`

### Namespaces

| Namespace | Base Controller | Purpose |
|-----------|----------------|---------|
| Root | `ApplicationController` | Storefront — home, products, cart, checkout, orders, wishlists, search, support |
| `/admin` | `Admin::BaseController` | Admin panel — 20 controllers, role-based |
| `/vendor` | `Vendor::SessionsController` | Vendor login/logout only |

### Models (24)

| Model | Key relationships |
|-------|-------------------|
| `Vendor` | has_many :admin_users, :products, :orders, :support_tickets; SoftDeletable |
| `HsnCode` | has_many :products; code + gst_rate for tax classification |
| `AdminUser` | has_secure_password; belongs_to :vendor (optional); role: 'admin'/'vendor' |
| `Product` | belongs_to :vendor, :category, :hsn_code; has_many :variants, :reviews; `properties` JSONB |
| `ProductVariant` | belongs_to :product; price, stock, color, size; `properties` JSONB |
| `Category` | self-referential tree (parent_id); `attribute_config` JSONB; has_one_attached :image |
| `Banner` | has_one_attached :image; `visible` = active + current + ordered |
| `HomepageCollection` | has_many :items; layout_type: grid_4/grid_3/grid_2/bento/asymmetric |
| `HomepageCollectionItem` | belongs_to :homepage_collection; has_one_attached :image |
| `Customer` | has_secure_password; has_many :addresses, :orders, :reviews, :wishlists |
| `Order` | lifecycle: pending→confirmed→processing→shipped→delivered; belongs_to :checkout_session; HSN tax; split by vendor; fee breakdown (platform/gateway/gst); vendor_earnings; refund_status |
| `OrderItem` | denormalized vendor_id |
| `Cart` / `CartItem` | token-based; optional customer |
| `Coupon` | percentage or fixed; usage tracking |
| `Review` | moderated; updates product average_rating |
| `SupportTicket` / `TicketMessage` | customer↔vendor↔admin; polymorphic sender |
| `CheckoutSession` | groups multiple vendor orders under one payment; tracks payment/refund state |
| `StoreSetting` | singleton; `filter_config` JSONB controls storefront filter visibility |

All models include `SoftDeletable` concern.

### Multi-Vendor Order & Payment System

**Architecture**: One customer payment covers multiple vendor orders (Amazon/Flipkart style)

**Flow**:
1. Cart items grouped by `product.vendor_id`
2. One `Order` created per vendor
3. Single `CheckoutSession` groups all orders
4. One Razorpay payment for total amount
5. Each vendor manages their order independently
6. Partial refunds supported (cancel individual orders)
7. Per-vendor payouts with fee deductions

**Key Models**:
- `CheckoutSession` - Groups orders, tracks payment state
- `Order` - Per-vendor order with fee breakdown
- `PaymentLog` - Audit trail per order

**See**: [multi-vendor-payments](../multi-vendor-payments/SKILL.md) for detailed architecture

### Homepage (`HomeController#index`)

1. `@banners` → carousel
2. `@homepage_collections` → dynamic sections
3. `@categories` → Shop by Category grid (with images)
4. `@featured_products` → Bestsellers
5. `@new_arrivals` → New Arrivals

Admin-only (vendors cannot manage homepage).

### Key Directories

```
app/controllers/admin/      — 20 admin controllers
app/controllers/vendor/     — Vendor sessions
app/views/admin/            — admin CRUD views
app/views/home/             — homepage + collection partials
app/views/shared/           — _product_card, etc.
app/javascript/controllers/ — 25 Stimulus controllers
db/migrate/                 — 34 migrations
lib/tasks/                  — seed tasks
```

### Conventions

- Admin forms: `bg-white rounded-lg shadow-sm p-6`, indigo buttons
- Storefront: `rounded-xl`/`2xl`, rose accents, serif headings
- Scopes: `active`, `ordered`, `visible`; `for_vendor` on Order/SupportTicket
- Admin toggle: `toggle_status` action + `PATCH` route
- Vendor scoping: `vendor_scoped(scope)` helper; vendor_id set server-side
- Uploads: `OrganizedUploads` concern; S3 keys: `vendors/{id}/products/{token}.ext`

### Credentials

- Admin: `admin@noralooks.com` / `password123`
- Vendor 1-3: `vendor1@noralooks.com` / `password123` (Laxmi Gold House), `vendor2@` (Shree Diamonds), `vendor3@` (Royal Gems)
- Customer: `demo@example.com` / `password123`

## Feature Skills

Detailed documentation for major features lives in separate skill files:

- **[multi-vendor-payments](../multi-vendor-payments/SKILL.md)** — Multi-vendor checkout, single payment for multiple orders, Razorpay integration, partial refunds, per-vendor payouts, fee calculations
- **[category-attributes](../category-attributes/SKILL.md)** — Dynamic attribute config system, per-category options, dual storage, form loading, admin config editor
- **[product-variants](../product-variants/SKILL.md)** — Product/variant creation, inline default variant, pricing, stock, auto-generation, forms
- **[search-and-filtering](../search-and-filtering/SKILL.md)** — Search scopes, autocomplete, storefront filters, admin-configurable filter visibility, category tree expansion, known gaps

## Rake Tasks

```bash
rails db:seed              # everything
rails seed:homepage        # admin, categories (with attribute_config), subcategories, banners, collections, coupons
rails seed:hsn_codes       # HSN codes for tax
rails seed:vendors         # sample vendors
rails seed:products        # products, variants, inventory
rails seed:orders          # customers, addresses, reviews, orders
```
