# Auracraft Project Knowledge Base

## Project Overview
E-commerce platform for artificial jewellery and ethnic wear.

## Recent Changes - Homepage Settings

### Homepage Settings Feature
- **Model**: `HomepageSetting` with singleton pattern for site-wide configuration
- **Configurable Sections**:
  - Flash Sale (with animated badge)
  - Promotional Banner
  - Gifts & Celebrations (Perfect Presents)
  - Artisan Collection (Handcrafted with Love)
  - Ethnic Wear Collection
  - Hot Selling Items (Trending Now)
- **Admin**: `/admin/homepage_settings` for enabling/disabling and customizing sections

### Hot Selling Products
- Products can be marked as "Hot Selling" in the product edit page
- Appears in "Trending Now" section on homepage
- Includes functional add-to-cart with quantity controls

### Database Migrations
1. `CreateHomepageSettings` - Settings table with flash sale, promo banner config
2. `AddHotSellingToProducts` - hot_selling boolean column on products
3. `AddSectionTogglesToHomepageSettings` - Enable/disable toggles for homepage sections

## Commands

### Database Migrations
```bash
rails db:migrate
```

### Initialize Homepage Settings (first time only)
```bash
rails runner "HomepageSetting.current"
```

## Key Files

### Homepage Settings
- Model: `app/models/homepage_setting.rb`
- Controller: `app/controllers/admin/homepage_settings_controller.rb`
- Views: `app/views/admin/homepage_settings/`
- Homepage Sections: `app/views/home/sections/`

### Product Hot Selling
- Model: `app/models/product.rb` (hot_selling scope)
- Admin Form: `app/views/admin/products/_form.html.erb`
- Controller: `app/controllers/admin/products_controller.rb`
- Homepage: `app/views/home/sections/_trending.html.erb`

### Routes
```ruby
# Admin routes
resource :homepage_settings, only: [:show, :edit, :update]
```

## Usage

### Mark Products as Hot Selling
1. Go to Admin → Products
2. Edit a product
3. Check "Hot Selling" checkbox
4. Save
5. Product appears in "Trending Now" section on homepage

### Toggle Homepage Sections
1. Go to Admin → Homepage Settings
2. Click "Edit Settings"
3. Use checkboxes to enable/disable sections
4. Save changes

### Customize Flash Sale
1. Edit Homepage Settings
2. Modify Flash Sale fields (title, discount, CTA, etc.)
3. Set optional end date for time-limited sales
4. Save

## Assets
- Tom Select loaded from CDN in admin layout (for product searches)
- No custom build step required

## Testing
- No specific test commands added
- Standard Rails testing applies

## Notes
- Homepage Settings uses singleton pattern (only one settings record)
- All sections default to enabled
- Hot Selling products require at least one product marked in admin
- Flash Sale can have an optional end date
