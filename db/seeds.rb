# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.

puts "Creating admin user..."
AdminUser.find_or_create_by!(email: 'admin@auracraft.com') do |admin|
  admin.name = 'Admin User'
  admin.password = 'password123'
  admin.active = true
end

puts "Creating categories..."
categories = [
  { name: 'Electronics', slug: 'electronics', description: 'Latest gadgets and electronic devices' },
  { name: 'Clothing', slug: 'clothing', description: 'Fashion and apparel for everyone' },
  { name: 'Home & Garden', slug: 'home-garden', description: 'Everything for your home' },
  { name: 'Sports & Outdoors', slug: 'sports-outdoors', description: 'Gear for active lifestyles' },
  { name: 'Beauty & Health', slug: 'beauty-health', description: 'Personal care products' },
  { name: 'Books & Media', slug: 'books-media', description: 'Books, music, and movies' }
]

categories.each do |cat|
  Category.find_or_create_by!(slug: cat[:slug]) do |c|
    c.name = cat[:name]
    c.description = cat[:description]
    c.active = true
    c.position = 0
  end
end

puts "Creating products..."
electronics = Category.find_by(slug: 'electronics')
clothing = Category.find_by(slug: 'clothing')
home = Category.find_by(slug: 'home-garden')

products_data = [
  {
    name: 'Wireless Bluetooth Headphones',
    slug: 'wireless-bluetooth-headphones',
    description: 'Premium wireless headphones with active noise cancellation, 30-hour battery life, and superior sound quality.',
    short_description: 'Premium wireless headphones with ANC',
    category: electronics,
    price: 199.99,
    featured: true,
    variants: [
      { name: 'Black', price: 199.99, compare_at_price: 249.99, stock_quantity: 50 },
      { name: 'White', price: 199.99, compare_at_price: 249.99, stock_quantity: 35 },
      { name: 'Blue', price: 209.99, compare_at_price: 259.99, stock_quantity: 20 }
    ]
  },
  {
    name: 'Smart Watch Pro',
    slug: 'smart-watch-pro',
    description: 'Advanced smartwatch with health monitoring, GPS, and 7-day battery life.',
    short_description: 'Advanced smartwatch with health monitoring',
    category: electronics,
    price: 349.99,
    featured: true,
    variants: [
      { name: '42mm - Black', price: 349.99, stock_quantity: 40 },
      { name: '42mm - Silver', price: 349.99, stock_quantity: 30 },
      { name: '46mm - Black', price: 399.99, stock_quantity: 25 }
    ]
  },
  {
    name: 'Premium Cotton T-Shirt',
    slug: 'premium-cotton-tshirt',
    description: 'Ultra-soft 100% organic cotton t-shirt. Pre-shrunk and durable.',
    short_description: 'Ultra-soft organic cotton t-shirt',
    category: clothing,
    price: 29.99,
    featured: false,
    variants: [
      { name: 'Small - White', price: 29.99, stock_quantity: 100 },
      { name: 'Medium - White', price: 29.99, stock_quantity: 150 },
      { name: 'Large - White', price: 29.99, stock_quantity: 120 },
      { name: 'Small - Black', price: 29.99, stock_quantity: 100 },
      { name: 'Medium - Black', price: 29.99, stock_quantity: 150 },
      { name: 'Large - Black', price: 29.99, stock_quantity: 120 }
    ]
  },
  {
    name: 'Designer Denim Jeans',
    slug: 'designer-denim-jeans',
    description: 'Classic fit designer jeans made with premium stretch denim.',
    short_description: 'Classic fit premium denim jeans',
    category: clothing,
    price: 89.99,
    featured: true,
    variants: [
      { name: '30W x 32L', price: 89.99, stock_quantity: 50 },
      { name: '32W x 32L', price: 89.99, stock_quantity: 60 },
      { name: '34W x 32L', price: 89.99, stock_quantity: 55 },
      { name: '36W x 32L', price: 89.99, stock_quantity: 40 }
    ]
  },
  {
    name: 'Modern Table Lamp',
    slug: 'modern-table-lamp',
    description: 'Elegant modern table lamp with touch dimmer and USB charging port.',
    short_description: 'Modern lamp with touch dimmer',
    category: home,
    price: 79.99,
    featured: false,
    variants: [
      { name: 'Brushed Nickel', price: 79.99, stock_quantity: 30 },
      { name: 'Matte Black', price: 79.99, stock_quantity: 25 },
      { name: 'Rose Gold', price: 89.99, compare_at_price: 99.99, stock_quantity: 15 }
    ]
  },
  {
    name: 'Portable Bluetooth Speaker',
    slug: 'portable-bluetooth-speaker',
    description: 'Waterproof portable speaker with 360-degree sound and 20-hour battery.',
    short_description: 'Waterproof portable speaker',
    category: electronics,
    price: 129.99,
    featured: true,
    variants: [
      { name: 'Black', price: 129.99, stock_quantity: 70 },
      { name: 'Blue', price: 129.99, stock_quantity: 50 },
      { name: 'Red', price: 129.99, stock_quantity: 45 }
    ]
  }
]

products_data.each do |pdata|
  product = Product.find_or_create_by!(slug: pdata[:slug]) do |p|
    p.name = pdata[:name]
    p.description = pdata[:description]
    p.short_description = pdata[:short_description]
    p.category = pdata[:category]
    p.price = pdata[:price]
    p.active = true
    p.featured = pdata[:featured]
  end

  pdata[:variants].each_with_index do |vdata, index|
    ProductVariant.find_or_create_by!(product: product, name: vdata[:name]) do |v|
      v.sku = "#{product.slug.upcase.gsub('-', '')}-#{index + 1}"
      v.price = vdata[:price]
      v.compare_at_price = vdata[:compare_at_price]
      v.stock_quantity = vdata[:stock_quantity]
      v.active = true
      v.position = index
    end
  end
end

puts "Creating coupons..."
Coupon.find_or_create_by!(code: 'WELCOME10') do |c|
  c.name = 'Welcome Discount'
  c.description = '10% off your first order'
  c.discount_type = 'percentage'
  c.discount_value = 10
  c.minimum_order_amount = 50
  c.active = true
end

Coupon.find_or_create_by!(code: 'SAVE20') do |c|
  c.name = 'Save $20'
  c.description = '$20 off orders over $100'
  c.discount_type = 'fixed'
  c.discount_value = 20
  c.minimum_order_amount = 100
  c.active = true
end

puts "Creating banners..."
Banner.find_or_create_by!(title: 'Summer Sale') do |b|
  b.subtitle = 'Up to 50% off on selected items'
  b.link_url = '/products'
  b.active = true
  b.position = 0
end

Banner.find_or_create_by!(title: 'New Arrivals') do |b|
  b.subtitle = 'Check out our latest products'
  b.link_url = '/products?sort=newest'
  b.active = true
  b.position = 1
end

puts "Creating demo customer..."
Customer.find_or_create_by!(email: 'demo@example.com') do |c|
  c.first_name = 'Demo'
  c.last_name = 'User'
  c.password = 'password123'
  c.phone = '555-123-4567'
  c.active = true
end

puts "Seeds completed!"
puts ""
puts "Admin Login:"
puts "  Email: admin@auracraft.com"
puts "  Password: password123"
puts ""
puts "Demo Customer Login:"
puts "  Email: demo@example.com"
puts "  Password: password123"
