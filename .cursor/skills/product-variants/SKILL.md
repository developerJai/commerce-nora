---
name: product-variants
description: Documents product and variant creation, editing, inline default variant, pricing, stock, and the product form flow. Use when working on product CRUD, variant management, product forms, or fixing product/variant-related issues.
---

# Products & Variants

## Data Model

**Product** — the listing (name, description, images, category, vendor, attributes)
**ProductVariant** — the purchasable unit (price, stock, SKU, color, size, image)

Every product must have at least one variant. The variant holds the selling price and stock — products without variants show as "out of stock / ₹0" on the storefront.

### Product Columns

`name`, `slug`, `sku`, `price` (reference only), `description`, `short_description`, `active`, `featured`, `average_rating`, `ratings_count`, `category_id`, `vendor_id`, `hsn_code_id`, `base_material`, `plating`, `gemstone`, `occasion`, `ideal_for`, `country_of_origin`, `properties` (JSONB)

### Variant Columns

`name`, `sku`, `price`, `compare_at_price`, `stock_quantity`, `weight`, `color`, `size`, `active`, `position`, `reorder_point`, `product_id`, `properties` (JSONB)

## Creation Flow

### New Product (with inline default variant)

1. Vendor/admin visits `GET /admin/products/new`
2. Controller: `@product = Product.new; @product.variants.build`
3. Form renders:
   - Basic info (name, slug, category, HSN, vendor, descriptions, SKU, base price)
   - **Dynamic product attributes** (loaded from category config via Stimulus)
   - **Default Variant section** (price, stock, SKU, color, size, weight, image — also dynamic)
   - Product images, active/featured toggles
4. On submit, `Product.create` with `accepts_nested_attributes_for :variants`
5. Validation: `must_have_at_least_one_variant` (on: :create) — rejects if no variant
6. Variant auto-generates: `name` from color+size, `sku` if blank

### Edit Product

Product attributes only — no inline variant editing. Variants are managed separately via `Admin::ProductVariantsController`.

### Variant CRUD

Standalone form at `/admin/products/:id/variants/new` or `edit`. Dropdowns come from `product.category.variant_attribute_definitions`.

## Scopes & Helpers

```ruby
Product.active          # active=true AND vendor active
Product.featured        # featured=true
Product.with_category   # filter by category_id
Product.search(q)       # ILIKE on name, description, short_description
Product.ordered         # created_at DESC

ProductVariant.active   # active=true, not soft-deleted
ProductVariant.ordered  # position ASC, created_at ASC
```

### Key Product Methods

```ruby
product.default_variant     # first active variant by position, or first variant
product.price_range         # [min, max] from active variants
product.min_price           # minimum active variant price
product.in_stock?           # any active variant with stock > 0?
product.filled_attributes   # {label => value} from category config
```

### Key Variant Methods

```ruby
variant.on_sale?            # compare_at_price > price
variant.discount_percentage # calculated from compare_at_price vs price
variant.adjust_stock!(qty, reason, admin)  # creates StockAdjustment record
variant.correct_stock!(new_qty, reason, admin)
```

## Auto-Generation

- **Product slug**: from `name.parameterize`, with counter for uniqueness
- **Product SKU**: from name prefix + random hex, e.g. `PEARLDR-A3F2`
- **Variant name**: from `color / size` if name blank (e.g. "Gold / Free Size")
- **Variant SKU**: from product SKU + random hex

## Admin Controller

```ruby
# Admin::ProductsController
before_action :set_product, only: [:show, :edit, :update, :destroy]

def new
  @product = Product.new
  @product.variants.build  # pre-build one variant for the inline form
end

def product_params
  # Permits: standard fields + variants_attributes + properties hash
end

# Dynamic attribute endpoint
def attribute_fields
  # GET /admin/products/attribute_fields?category_id=X
  # Returns _attribute_fields partial for the given category
end
```

## Storefront Display

- **Product card** (`_product_card.html.erb`): uses `default_variant` for price, `on_sale?` for badge, variant image fallback to product images
- **Product show** (`products/show.html.erb`): gallery, variant selector, price display, tabs (description, product details from `filled_attributes`, shipping)
- **Price display**: `default_variant.price` with `compare_at_price` struck-through if on sale

## Key Files

```
app/models/product.rb
app/models/product_variant.rb
app/controllers/admin/products_controller.rb
app/controllers/admin/product_variants_controller.rb
app/views/admin/products/_form.html.erb           # main product form with inline variant
app/views/admin/products/show.html.erb            # product detail + variants table
app/views/admin/product_variants/_form.html.erb   # standalone variant form
app/views/shared/_product_card.html.erb
app/views/products/show.html.erb                  # storefront product page
```

## Conventions

- Variant is the source of truth for price and stock — product `price` column is reference only
- Always build a variant with `@product.variants.build` on `new` action
- Use `default_variant` for storefront display (first active by position)
- Vendor scoping: `vendor_scoped(Product)` in controllers, `vendor_id` set server-side
- Images: product `has_many_attached :images`, variant `has_one_attached :image`
