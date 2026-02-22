# Homepage Settings

## Overview
Homepage Settings provides a centralized configuration system for controlling which sections appear on the homepage and their content.

## Features

### Configurable Sections
All sections can be enabled/disabled from the admin panel:

1. **Flash Sale**
   - Dynamic discount banner with animated badge
   - Customizable: title, heading, description, discount %, CTA button
   - Optional end date for time-limited sales
   - Location: `app/views/home/sections/_flash_sale.html.erb`

2. **Promotional Banner**
   - Coupon code promotion banner
   - Customizable: title, heading, promo code, CTA button
   - Location: Main banner in `app/views/home/index.html.erb`

3. **Gifts & Celebrations** (Perfect Presents)
   - Gift-focused product section
   - Toggle: `gifts_section_enabled`
   - Location: `app/views/home/sections/_gifts.html.erb`

4. **Artisan Collection** (Handcrafted with Love)
   - Jewellery collection showcase
   - Toggle: `artisan_section_enabled`
   - Location: `app/views/home/sections/_artisan.html.erb`

5. **Ethnic Wear Collection**
   - Traditional wear section
   - Toggle: `ethnic_section_enabled`
   - Location: `app/views/home/sections/_ethnic.html.erb`

6. **Hot Selling Items** (Trending Now)
   - Products marked with `hot_selling: true` in admin
   - Fully functional add-to-cart with quantity controls
   - Location: `app/views/home/sections/_trending.html.erb`

### Admin Interface
- **URL**: `/admin/homepage_settings`
- **View Settings**: Shows current configuration for all sections
- **Edit Settings**: Toggle sections on/off, customize content

## Database

### HomepageSetting Model
- Singleton pattern (only one record)
- Fields:
  - `flash_sale_enabled`, `flash_sale_title`, `flash_sale_heading`, `flash_sale_description`
  - `flash_sale_discount`, `flash_sale_cta_text`, `flash_sale_cta_link`, `flash_sale_ends_at`
  - `promo_banner_enabled`, `promo_banner_title`, `promo_banner_heading`
  - `promo_banner_code`, `promo_banner_cta_text`, `promo_banner_cta_link`
  - `gifts_section_enabled`, `artisan_section_enabled`, `ethnic_section_enabled`

### Migrations
1. `CreateHomepageSettings` - Initial settings table
2. `AddSectionTogglesToHomepageSettings` - Section visibility toggles

## Key Files

```
app/models/homepage_setting.rb
app/controllers/admin/homepage_settings_controller.rb
app/views/admin/homepage_settings/
  - show.html.erb
  - edit.html.erb
app/views/home/sections/
  - _flash_sale.html.erb
  - _trending.html.erb
  - _gifts.html.erb
  - _artisan.html.erb
  - _ethnic.html.erb
```

## Usage

### Mark Products as Hot Selling
1. Go to Admin → Products
2. Edit a product
3. Check "Hot Selling" checkbox
4. Save
5. Product appears in "Trending Now" section

### Toggle Section Visibility
1. Go to Admin → Homepage Settings
2. Click "Edit Settings"
3. Use checkboxes in "Homepage Sections Visibility"
4. Save changes

### Customize Flash Sale
1. Edit Homepage Settings
2. Modify Flash Sale section fields
3. Set optional end date
4. Save

## Commands

```bash
# Run migrations
rails db:migrate

# Initialize settings (first time only)
rails runner "HomepageSetting.current"
```

## Notes
- Hot Selling uses existing product `hot_selling` boolean column
- All sections default to enabled
- Settings persist until manually changed
- No rake tasks required for this feature
