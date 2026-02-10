---
name: search-and-filtering
description: Documents search, autocomplete, and product filtering in the Noralooks storefront and admin panel. Use when working on search features, product filtering, autocomplete suggestions, or fixing search-related bugs.
---

# Search & Filtering

## Entry Points

| URL | Controller | Purpose |
|-----|-----------|---------|
| `GET /search?q=` | `SearchController#index` | Storefront full-page search results |
| `GET /search/suggestions?q=` | `SearchController#suggestions` | Autocomplete JSON API |
| `GET /products?...` | `ProductsController#index` | Storefront browse + filter |
| `GET /admin/products?q=...` | `Admin::ProductsController#index` | Admin search + filter |

## Core Search Scope

```ruby
scope :search, ->(query) {
  where("name ILIKE :q OR description ILIKE :q OR short_description ILIKE :q", q: "%#{query}%") if query.present?
}
```

Simple `ILIKE '%term%'` — no full-text indexing, no trigram search.

## Storefront Filters (`/products`)

### Available Filter Params

| Param | Type | Example |
|-------|------|---------|
| `category_ids[]` | multi-select | `?category_ids[]=1&category_ids[]=3` |
| `min_price` / `max_price` | range slider | `?min_price=500&max_price=5000` |
| `colors[]` | multi-select | `?colors[]=Gold&colors[]=Silver` |
| `materials[]` | multi-select | `?materials[]=Brass&materials[]=Alloy` |
| `gemstones[]` | multi-select | `?gemstones[]=Kundan&gemstones[]=CZ` |
| `occasions[]` | multi-select | `?occasions[]=Wedding` |
| `discount` | radio | `?discount=20` (20% and above) |
| `rating` | radio | `?rating=4` (4★ and above) |
| `in_stock` | toggle | `?in_stock=1` |
| `sort` | single | `rating`, `price_low`, `price_high`, `discount`, `newest` |

### Filter Scopes (Product model)

```ruby
Product.by_attribute(:base_material, ["Brass", "Gold"])  # column-based filter
Product.by_property("fabric_type", ["Silk"])              # JSONB property filter
Product.by_color(["Gold", "Silver"])                      # variant color filter
Product.by_discount(20)                                   # 20%+ off
Product.by_rating(4)                                      # 4★ and above
Product.in_stock_only                                     # stock > 0
Product.available_filter_values(:base_material)           # faceted counts {value => count}
Product.available_colors                                  # variant color facets
```

### Filter UI Components

- **Active filter chips**: Removable pills at the top showing all selected filters with "Clear all"
- **Availability toggle**: "In Stock Only" switch at top of sidebar
- **Collapsible sections**: Each filter group has toggle header with chevron (Stimulus: `filter_section_controller.js`)
- **Categories**: Accordion-style tree with expand/collapse per parent (Stimulus: `category_filter_controller.js`), product count badges, rose tint for selected, auto-expand when active
- **Price range**: Dual slider with live labels
- **Color**: Visual pill tags with color swatch circles + count
- **Material / Stone Type / Occasion**: Checkboxes with faceted counts
- **Discount**: Radio buttons (10%, 20%, 30%, 40%, 50% and above) with tag icons, clear option (`checked=false` to avoid DOM conflict)
- **Rating**: SVG star icons with radio buttons (4★, 3★, 2★ and above), clear option (`checked=false`)
- **Faceted counts**: Each filter option shows `(N)` count from current result set
- **Empty category hiding**: Categories/subcategories with 0 products are excluded from the filter tree

### Mobile UX

- **Filter button**: Fixed at top, shows active filter count badge
- **Slide-out drawer**: Right-side drawer with overlay backdrop (Stimulus: `filter_drawer_controller.js`)
- **Same form**: Shared `_filter_form.html.erb` partial used in both desktop sidebar and mobile drawer
- **Sort dropdown**: Native `<select>` on mobile, tab bar on desktop

### Category Filter Logic

- **Family-tree expansion**: Selecting a parent includes products on the parent + all children. Selecting a child also includes products assigned directly to the parent (bidirectional).
- **Empty hiding**: `Category.grouped_for_filters(product_counts:)` accepts a counts hash and excludes categories with 0 products.
- **Subcategory toggle**: Admin can disable subcategories via Store Settings; when off, only parent categories render (no expand arrows).

### Admin-Configurable Filter Visibility

`StoreSetting` (singleton model, `filter_config` JSONB) controls which filter components appear on the storefront.

```ruby
StoreSetting.instance.effective_filter_config
# => {"show_availability"=>true, "show_categories"=>true, "show_subcategories"=>true, ...}
```

**Admin UI**: `/admin/store_settings` — toggle switches for each filter with icons and descriptions. Admin-only (`require_admin_role!`).

| Key | Controls |
|-----|----------|
| `show_availability` | In Stock toggle |
| `show_categories` | Parent category checkboxes |
| `show_subcategories` | Nested children under parents |
| `show_price_range` | Min/max price slider |
| `show_color` | Color swatch badges |
| `show_material` | Material checkboxes |
| `show_stone_type` | Gemstone checkboxes |
| `show_occasion` | Occasion checkboxes |
| `show_discount` | Discount radio buttons |
| `show_rating` | Star rating radio buttons |

The storefront `_filter_form.html.erb` reads `@filter_config` and wraps each section in `<% if fc["show_*"] %>`.

### Controller Flow

1. Parse all filter params from URL
2. Build base `Product.active` query with eager loads
3. Expand category selections (parent↔child family tree)
4. Chain filter scopes conditionally
5. Compute `@facets` (faceted counts for color/material/stone/occasion from filtered set)
6. Compute `@category_counts` and build `@category_tree` (excludes empties)
7. Load `@filter_config` from `StoreSetting.instance`
8. Build `@active_filters` array for chip display
9. Apply sort + paginate
10. Respond HTML or Turbo Stream

### Auto-submit

The form uses `filters` Stimulus controller with 400ms debounce. Every `change` event (checkbox, radio, slider commit) triggers auto-submit. No manual "Apply" button needed.

## Autocomplete (`/search/suggestions`)

Three parallel queries:
1. Categories — `name ILIKE` — max 3
2. Products — `name ILIKE OR description ILIKE` — max 5
3. Variants — `name ILIKE OR sku ILIKE` — max 5

Stimulus: `search_autocomplete_controller.js`, 200ms debounce, 2-char minimum.

## Admin Filters (`/admin/products`)

- Text search: `Product.search` scope
- Category: single dropdown
- Vendor: single dropdown (admin only)
- Status tabs: All / Active / Draft / Featured

## Key Files

```
app/controllers/products_controller.rb              # storefront filters + facets + filter_config
app/controllers/admin/store_settings_controller.rb  # admin filter visibility settings
app/controllers/search_controller.rb                # search + suggestions
app/models/product.rb                               # filter scopes, facet methods
app/models/store_setting.rb                         # singleton — filter_config JSONB
app/models/category.rb                              # grouped_for_filters(product_counts:)
app/views/products/index.html.erb                   # products grid + sidebar + mobile drawer
app/views/products/_filter_form.html.erb            # shared filter form (desktop + mobile), respects @filter_config
app/views/admin/store_settings/show.html.erb        # admin toggle UI for filter visibility
app/javascript/controllers/filters_controller.js    # auto-submit with debounce
app/javascript/controllers/filter_section_controller.js  # collapsible sections
app/javascript/controllers/filter_drawer_controller.js   # mobile slide-out drawer
app/javascript/controllers/category_filter_controller.js # accordion expand/collapse per category
app/javascript/controllers/price_range_controller.js     # dual range slider
app/javascript/controllers/search_autocomplete_controller.js
```

## Known Gaps

1. **`app/views/search/index.html.erb` does not exist** — full search results page will error
2. **Column attributes not in text search** — searching "Kundan" won't match product.gemstone
3. **JSONB properties not in text search** — searching "Banarasi" won't match properties
4. **`ILIKE '%term%'`** — no index usage, sequential scan on large catalogs
5. **Autocomplete missing `short_description`** — inconsistent with main search scope
