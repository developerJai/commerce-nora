# Noralooks E-Commerce Platform

A modern, full-featured e-commerce MVP built with Ruby on Rails 8, featuring a customer storefront and admin panel.

## Features

### Storefront
- **Product Browsing**: Search, filter, and browse products by category
- **Smart Search**: Autocomplete suggestions for products, variants, and categories
- **Shopping Cart**: Add/remove items, quantity controls, stock validation
- **Checkout**: Address management, coupon codes, cash on delivery
- **Order Management**: Track order status, view order history
- **Product Reviews**: Rate and review purchased products
- **Support Tickets**: Customer support system with messaging
- **Mobile Responsive**: Optimized for all device sizes with bottom navigation

### Admin Panel
- **Dashboard**: Overview of sales, orders, and key metrics
- **Product Management**: Products, variants, images, pricing
- **Inventory Management**: Stock tracking, adjustments, reorder reports
- **Order Processing**: Draft orders, fulfillment stages, order management
- **Customer Management**: View profiles, orders, enable/disable accounts
- **Marketing**: Banners, coupons, discount management
- **Reviews & Support**: Moderate reviews, handle support tickets
- **Reports**: Sales, products, and customer analytics

## Tech Stack

- **Framework**: Ruby on Rails 8.0
- **Database**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Authentication**: BCrypt (custom implementation)
- **File Storage**: Active Storage
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Deployment**: Kamal (Docker-based)

## Requirements

- Ruby 3.2.0+
- PostgreSQL 14+
- Node.js 18+ (for Tailwind CSS)
- ImageMagick or libvips (for image processing)

## Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/noralooks.git
cd noralooks
```

### 2. Install Dependencies

```bash
# Install Ruby dependencies
bundle install

# Install JavaScript dependencies (if any)
bin/importmap pin --all
```

### 3. Configure Environment

```bash
# Edit credentials
EDITOR=vim rails credentials:edit

# Add AWS credentials
aws:
   access_key_id: xxx
   secret_access_key: xxx
   bucket_name: xxx
   region: xxx
   cdn_host: https://xxxxx
```

### 4. Setup Database

```bash
# Create and migrate databases
bin/rails db:create db:migrate

# Seed with sample data (optional)
bin/rails db:seed
```

### 5. Setup Active Storage

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

### 6. Start Development Server

```bash
# Using Foreman (recommended - runs Rails + Tailwind CSS watcher)
bin/dev

# Or manually
bin/rails server
# In another terminal:
bin/rails tailwindcss:watch
```

The application will be available at:
- **Storefront**: http://localhost:3000
- **Admin Panel**: http://localhost:3000/admin

### Default Admin Credentials

After seeding the database:
- **Email**: admin@noralooks.com
- **Password**: password123

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection URL | Uses database.yml |
| `RAILS_MASTER_KEY` | Master key for credentials | From credentials file |
| `RAILS_ENV` | Environment (development/test/production) | development |
| `RAILS_MAX_THREADS` | Database connection pool size | 5 |
| `WEB_CONCURRENCY` | Puma worker processes | 1 |
| `SOLID_QUEUE_IN_PUMA` | Run jobs in web process | false |

## Testing

```bash
# Run all tests
bin/rails test

# Run system tests
bin/rails test:system

# Run specific test file
bin/rails test test/models/product_test.rb
```

## Code Quality

```bash
# Run security scanner
bin/brakeman

# Run linter
bin/rubocop

# Auto-fix linting issues
bin/rubocop -A
```

## Production Setup

### Using Kamal (Recommended)

1. **Configure deployment settings**

Edit `config/deploy.yml`:
```yaml
service: noralooks
image: your-dockerhub-username/noralooks

servers:
  web:
    - your-server-ip

proxy:
  ssl: true
  host: your-domain.com

registry:
  username: your-dockerhub-username
```

2. **Set up secrets**

Edit `.kamal/secrets`:
```bash
KAMAL_REGISTRY_PASSWORD=your-docker-registry-token
RAILS_MASTER_KEY=your-master-key
NORALOOKS_DATABASE_PASSWORD=your-db-password
```

3. **Deploy**

```bash
# First-time setup
bin/kamal setup

# Subsequent deployments
bin/kamal deploy

# View logs
bin/kamal logs

# Open Rails console
bin/kamal console
```

### Using Docker Directly

```bash
# Build image
docker build -t noralooks .

# Run container
docker run -d \
  -p 3000:3000 \
  -e RAILS_ENV=production \
  -e RAILS_MASTER_KEY=your-key \
  -e DATABASE_URL=postgres://user:pass@host/db \
  noralooks
```

### Database Setup (Production)

```bash
# Create production databases
RAILS_ENV=production bin/rails db:create

# Run migrations
RAILS_ENV=production bin/rails db:migrate

# Seed initial data (if needed)
RAILS_ENV=production bin/rails db:seed
```

## Project Structure

```
app/
├── controllers/
│   ├── admin/           # Admin panel controllers
│   └── ...              # Storefront controllers
├── models/
│   ├── concerns/        # Shared model concerns (SoftDeletable, etc.)
│   └── ...              # ActiveRecord models
├── views/
│   ├── admin/           # Admin panel views
│   ├── layouts/         # Application layouts
│   └── shared/          # Shared partials
├── javascript/
│   └── controllers/     # Stimulus controllers
└── helpers/             # View helpers

config/
├── routes.rb            # Route definitions
├── database.yml         # Database configuration
├── deploy.yml           # Kamal deployment config
└── importmap.rb         # JavaScript imports

db/
├── migrate/             # Database migrations
├── schema.rb            # Current schema
└── seeds.rb             # Seed data
```

## Key Models

| Model | Description |
|-------|-------------|
| `AdminUser` | Admin panel users |
| `Customer` | Storefront customers |
| `Product` | Products with images |
| `ProductVariant` | Product variants (size, color, etc.) |
| `Category` | Product categories (hierarchical) |
| `Cart` / `CartItem` | Shopping cart |
| `Order` / `OrderItem` | Customer orders |
| `Coupon` | Discount coupons |
| `Review` | Product reviews |
| `SupportTicket` | Customer support |
| `StockAdjustment` | Inventory tracking |
| `Banner` | Homepage banners |

## API Endpoints

### Search Suggestions
```
GET /search/suggestions?q=query
```
Returns JSON with matching categories, products, and variants.

## Common Tasks

### Create Admin User

```ruby
# In Rails console
AdminUser.create!(
  name: "Admin Name",
  email: "admin@example.com",
  password: "secure_password",
  password_confirmation: "secure_password"
)
```

### Reset Admin Password

```ruby
# In Rails console
admin = AdminUser.find_by(email: "admin@example.com")
admin.update!(password: "new_password", password_confirmation: "new_password")
```

### Bulk Stock Adjustment

```ruby
# In Rails console
ProductVariant.find_each do |variant|
  variant.adjust_stock!(50, 'restock', adjusted_by: AdminUser.first, notes: 'Initial restock')
end
```

## Troubleshooting

### Database Connection Issues
```bash
# Check PostgreSQL is running
pg_isready

# Check database exists
psql -l | grep noralooks
```

### Asset Issues
```bash
# Recompile assets
bin/rails assets:precompile

# Clear asset cache
bin/rails assets:clobber
```

### Image Processing Issues
```bash
# Ensure ImageMagick is installed
convert -version

# Or use libvips
vips --version
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@noralooks.com or open an issue in the repository.
