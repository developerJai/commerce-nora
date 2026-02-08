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

### Storefront (root namespace)
- `ApplicationController` — base, session-based customer auth
- Routes: root `home#index`, `products#index/show`, `categories#show`, `cart`, `checkout`, `orders`, `wishlists`, `search`, `support_tickets`
- Layout: `app/views/layouts/application.html.erb` — sticky header, mobile bottom nav, full footer

### Admin (`/admin` namespace)
- `Admin::BaseController` — `layout 'admin'`, auth via `session[:admin_id]` → `AdminUser`
- 18 controllers: Dashboard, Products, ProductVariants, Categories, Inventory, Banners, HomepageCollections, HomepageCollectionItems, Orders, DraftOrders, Coupons, Customers, Reviews, SupportTickets, Reports, Sessions, Settings, Passwords
- Layout: `app/views/layouts/admin.html.erb` — dark sidebar (`bg-slate-900`), indigo accent buttons
- Sidebar link partial: `app/views/admin/shared/_sidebar_link.html.erb` (icon hash map)

### Models (21)

| Model | Key relationships |
|-------|-------------------|
| `Product` | has_many :variants, :reviews; has_many_attached :images; belongs_to :category |
| `ProductVariant` | belongs_to :product; has_one_attached :image; has stock/inventory fields |
| `Category` | self-referential tree (parent_id); scopes: `active`, `root`, `ordered` |
| `Banner` | has_one_attached :image; scopes: `visible` = active + current + ordered |
| `HomepageCollection` | has_many :items; layout_type: grid_4/grid_3/grid_2/bento/asymmetric |
| `HomepageCollectionItem` | belongs_to :homepage_collection; has_one_attached :image; overlay_position |
| `Customer` | has_secure_password; has_many :addresses, :orders, :reviews, :wishlists |
| `Order` | lifecycle: pending → confirmed → processing → shipped → delivered; `place!`, `ship!`, `deliver!`, `cancel!` |
| `Cart` / `CartItem` | token-based; belongs_to customer (optional) |
| `Coupon` | percentage or fixed discount; usage tracking |
| `Review` | moderated (approved boolean); updates product average_rating |
| `SupportTicket` / `TicketMessage` | polymorphic sender |

All models include `SoftDeletable` concern — `destroy` calls `soft_delete` (sets `deleted_at`).

### Homepage (`HomeController#index`)

Loads and renders in order:
1. `@banners` — `Banner.visible.limit(5)` → carousel
2. `@homepage_collections` — `HomepageCollection.visible` with items → dynamic sections
3. `@categories` — Shop by Category grid
4. `@featured_products` — Bestsellers
5. Promotional banner (hardcoded)
6. `@new_arrivals` — New Arrivals
7. Why Choose Us (hardcoded)

Homepage collection layout types:
- `grid_4` / `grid_3` / `grid_2` — equal-column grids
- `bento` — featured left (col-span + row-span) + 4 smaller right
- `asymmetric` — large left + 2 stacked right

Partials: `app/views/home/_homepage_collection.html.erb` → `app/views/home/layouts/_#{layout_type}.html.erb` → `_item_inner.html.erb`

Admin collection management features:
- Storefront preview on collection show page (`admin/homepage_collections/preview_layouts/`)
- Live preview card on item form with real-time overlay text (Stimulus `collection-item-preview` controller)
- Image validation: max 2 MB, JPG/PNG/WebP only (model + client-side)
- Recommended dimensions per layout type via `HomepageCollection::LAYOUT_DIMENSIONS`

### Key Directories

```
app/controllers/admin/     — 18 admin controllers
app/views/admin/           — admin CRUD views
app/views/admin/homepage_collections/preview_layouts/ — admin storefront preview partials
app/views/home/            — homepage + collection partials
app/views/home/layouts/    — layout type partials (grid_4, bento, etc.)
app/views/shared/          — _product_card, etc.
app/javascript/controllers/ — 22 Stimulus controllers
app/assets/tailwind/       — application.css (Tailwind + custom)
db/migrate/                — 27 migrations
lib/tasks/                 — rake tasks (seed:homepage, seed:products, seed:orders)
```

### Conventions

- Admin forms: white card (`bg-white rounded-lg shadow-sm p-6`), indigo buttons, gray borders
- Storefront cards: `rounded-xl`/`2xl`, rose accents, serif headings, hover transitions
- Scopes: `active`, `ordered`, `visible` on most models
- SKU format: `PRODUCTSLUG-VARIANTINDEX` (uppercase, no hyphens)
- All image uploads via Active Storage `has_one_attached :image` or `has_many_attached :images`
- Admin toggle pattern: `toggle_status` action + `PATCH` route

### Credentials

- Admin: `admin@noralooks.com` / `password123`
- Demo customer: `demo@example.com` / `password123`

## Rake Tasks

```bash
# Seed everything
rails db:seed

# Individual sections
rails seed:homepage    # Admin, categories, banners, homepage collections, coupons
rails seed:products    # Products, variants, inventory
rails seed:orders      # Customers, addresses, reviews, demo orders
```
