
## Bundle Deals & Homepage Settings

### Bundle Deals Feature
- **Model**: `BundleDeal` with image upload support and `BundleDealItem` for products
- **Admin**: Full CRUD at `/admin/bundle_deals` with searchable product select (Tom Select)
- **Homepage**: Dynamic section with images, products list, and "Add Bundle to Cart" functionality
- **Cart**: Bundles add multiple products at once with automatic discount tracking

### Homepage Settings
- **Model**: `HomepageSetting` with singleton pattern for site-wide configuration
- **Configurable Sections**:
  - Flash Sale (with animated badge)
  - Promotional Banner
  - Bundle Deals
  - Gifts & Celebrations
  - Artisan Collection
  - Ethnic Wear
- **Admin**: `/admin/homepage_settings` for enabling/disabling and customizing sections

### Database Migrations
1. `CreateHomepageSettings` - Settings table with flash sale, promo banner, bundle deals config
2. `CreateBundleDeals` - Bundle deals table with pricing and image support
3. `CreateBundleDealItems` - Junction table for bundle products
4. `AddSectionTogglesToHomepageSettings` - Enable/disable toggles for homepage sections

## Commands

### Run Bundle Deals Seed (Production Safe)
```bash
rails bundle_deals:seed
```
- Safe to run multiple times (uses `find_or_create_by`)
- Creates 3 default bundle deals
- Does NOT run other seeds

### Database Migrations
```bash
rails db:migrate
```

### Assets
- Tom Select loaded from CDN for searchable dropdowns
- No custom build step required

## Key Files
- Models: `app/models/bundle_deal.rb`, `app/models/bundle_deal_item.rb`, `app/models/homepage_setting.rb`
- Controllers: `app/controllers/admin/bundle_deals_controller.rb`, `app/controllers/admin/homepage_settings_controller.rb`
- Views: `app/views/admin/bundle_deals/`, `app/views/admin/homepage_settings/`, `app/views/home/sections/`
- Routes: Added `bundle_deals` and `homepage_settings` resources in admin namespace

## Testing
- No specific test commands added
- Standard Rails testing applies
