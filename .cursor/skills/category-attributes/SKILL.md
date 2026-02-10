---
name: category-attributes
description: Documents the category-driven dynamic attribute system for products and variants. Use when working on product attributes, category configuration, attribute forms, or the attribute config editor in the admin panel.
---

# Category-Driven Dynamic Attributes

Product/variant attributes are **not hardcoded** — they're defined per root category via the `attribute_config` JSONB column on `Category`. Child categories inherit from their parent.

## Config Structure

Stored on root categories as `attribute_config` JSONB:

```json
{
  "product_attributes": {
    "base_material": { "label": "Base Material", "required": true, "options": ["Sterling Silver", "Gold", ...] },
    "gemstone": { "label": "Gemstone / Stone Type", "required": false, "options": ["Diamond", "AD Stone", ...] }
  },
  "variant_attributes": {
    "color": { "label": "Color", "required": false, "options": ["Gold", "Silver", ...] },
    "size": { "label": "Size", "required": false, "options": ["Free Size", "Adjustable", ...] }
  }
}
```

Each attribute has: `label` (display name), `required` (boolean), `options` (array for dropdowns, empty = text field), optional `default`.

## Per-Category Configs

| Category | Product Attributes | Variant Sizes |
|----------|-------------------|---------------|
| Necklaces / Pendants | base_material, plating, gemstone, occasion, ideal_for, country_of_origin | 14"-30" chain lengths |
| Rings | same jewellery attrs | ring sizes 5-24 |
| Bangles | same jewellery attrs | 2.2-2.12 bangle sizes |
| Earrings / Bracelets | same jewellery attrs | Free Size, Adjustable |
| Traditional Wear | fabric_type, pattern, occasion, ideal_for, country_of_origin | XS-XXXL + numeric 32-46 |
| Gifts | gift_type, occasion, ideal_for, country_of_origin | Standard/Small/Medium/Large |

## Inheritance

- **Root categories** → use their own `attribute_config`
- **Child categories** → use `parent.attribute_config` (pure inheritance, no override)
- `Category#effective_attribute_config` handles this automatically

## Value Storage (Dual Strategy)

Standard columns are used when they exist; overflow goes to `properties` JSONB.

**Known DB columns** (`Category::PRODUCT_COLUMN_ATTRIBUTES`):
`base_material`, `plating`, `gemstone`, `occasion`, `ideal_for`, `country_of_origin`

**Known variant columns** (`Category::VARIANT_COLUMN_ATTRIBUTES`):
`color`, `size`

**Anything else** (e.g. `fabric_type`, `pattern`, `gift_type`) → stored in `properties` JSONB on products/variants.

Form field naming decides storage:
- Column exists → `product[base_material]` → saved to column
- No column → `product[properties][fabric_type]` → saved to `properties` JSONB

## Key Model Helpers

```ruby
# Category
Category#effective_attribute_config          # own if root, parent's if child
Category#product_attribute_definitions       # [{key:, label:, required:, options:}]
Category#variant_attribute_definitions       # same for variants
Category#options_for(attr_name)              # options array for a specific attribute

# Product
Product#attribute_value(key)                 # reads column first, then properties
Product#set_attribute_value(key, value)      # writes to column or properties
Product#filled_attributes                    # {label => value} for display
Product#validate_attribute_options           # validates values against category config

# ProductVariant — same pattern
ProductVariant#attribute_value(key)
ProductVariant#set_attribute_value(key, value)
```

## Dynamic Form Loading

When the vendor selects a category in the product form:

1. `category_attributes_controller.js` (Stimulus) fires on `change`
2. Fetches `GET /admin/products/attribute_fields?category_id=X&product_id=Y`
3. `Admin::ProductsController#attribute_fields` renders `_attribute_fields.html.erb`
4. Response contains `#dynamic-product-attributes` and `#dynamic-variant-attributes` divs
5. Stimulus replaces the targets in the form

Both product form (inline default variant) and standalone variant form use category config for dropdowns.

## Admin Config Editor

The category form (`_form.html.erb`) has a visual editor for root categories:

- **Preset templates**: Jewellery / Clothing / Gifts — one-click to populate all attributes + options
- **Dynamic cards**: Each attribute shows key, label, required checkbox, and option tags
- **Add/remove**: Plus/minus buttons for attributes and individual option values
- **Option pills**: Editable inline text inputs with X to remove
- **Serialization**: Stimulus controller `attribute_config_controller.js` serializes visual state to hidden `attribute_config` field as JSON on every change

Child categories show: "This subcategory inherits its attribute configuration from its parent category."

## Key Files

```
app/models/category.rb                           # effective_attribute_config, definitions, constants
app/models/product.rb                            # attribute_value, filled_attributes, validate_attribute_options
app/models/product_variant.rb                    # attribute_value, set_attribute_value
app/controllers/admin/products_controller.rb     # attribute_fields action, properties in product_params
app/controllers/admin/categories_controller.rb   # JSON parsing in category_params
app/views/admin/products/_attribute_fields.html.erb  # dynamic partial
app/views/admin/products/_form.html.erb          # category-attributes Stimulus targets
app/views/admin/product_variants/_form.html.erb  # variant form with category config
app/views/admin/categories/_form.html.erb        # visual attribute config editor
app/javascript/controllers/category_attributes_controller.js  # loads fields on category change
app/javascript/controllers/attribute_config_controller.js     # visual config editor with presets
lib/tasks/seed.rake                              # attribute_config seeds per root category
db/migrate/20260210150000_add_attribute_config_and_properties.rb
```

## Conventions

- **Never hardcode** attribute options as model constants
- All dropdowns come from `category.product_attribute_definitions` / `variant_attribute_definitions`
- Use `attribute_value(key)` for read, `set_attribute_value(key, value)` for write
- Check `Category::PRODUCT_COLUMN_ATTRIBUTES` before deciding storage location
- Presets in `attribute_config_controller.js` must stay in sync with seeds in `seed.rake`
