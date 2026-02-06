# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.

puts "Creating admin user..."
AdminUser.find_or_create_by!(email: 'admin@noralooks.com') do |admin|
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

puts "Creating bulk products for infinite scroll testing..."

seed_categories = Category.active.ordered.to_a

adjectives = %w[
  Classic Modern Minimal Elegant Premium Vintage Sleek Bold Soft Matte Glossy
  Refined Timeless Everyday Limited Signature Luxe
]

nouns = %w[
  Necklace Ring Bracelet Earrings Pendant Chain Bangle Charm Stud Hoops Anklet
  Watch Sunglasses Bag Wallet Scarf Candle Lamp Bottle Speaker Headphones
]

materials = %w[
  Gold Silver RoseGold Steel Leather Cotton Ceramic Pearl Crystal
]

target_products = 320
existing_seeded = Product.where("slug LIKE ?", "seed-%").count
to_create = [target_products - existing_seeded, 0].max

if to_create > 0
  to_create.times do |i|
    idx = existing_seeded + i + 1
    category = seed_categories[idx % seed_categories.size]

    name = "#{adjectives[idx % adjectives.size]} #{materials[idx % materials.size]} #{nouns[idx % nouns.size]}"
    slug = "seed-#{idx}-#{name.parameterize}"

    base_price = 15 + (idx % 250)
    featured = (idx % 11 == 0)

    product = Product.find_or_create_by!(slug: slug) do |p|
      p.name = name
      p.description = "#{name} designed for everyday wear with premium finishing and comfort."
      p.short_description = "#{adjectives[idx % adjectives.size]} #{nouns[idx % nouns.size].downcase}"
      p.category = category
      p.price = base_price
      p.active = true
      p.featured = featured
    end

    variant_count = 2 + (idx % 2)
    variant_names = (1..variant_count).map { |n| "Option #{n}" }

    variant_names.each_with_index do |vname, vindex|
      ProductVariant.find_or_create_by!(product: product, name: vname) do |v|
        v.sku = "#{product.slug.upcase.gsub('-', '')}-#{vindex + 1}"
        v.price = base_price + (vindex * 5)
        v.compare_at_price = (vindex == 0 && idx % 5 == 0) ? (base_price + 15) : nil
        v.stock_quantity = 20 + (idx % 80)
        v.active = true
        v.position = vindex
      end
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
demo_customer = Customer.find_or_create_by!(email: 'demo@example.com') do |c|
  c.first_name = 'Demo'
  c.last_name = 'User'
  c.password = 'password123'
  c.phone = '555-123-4567'
  c.active = true
end

srand(1234)

puts "Setting up inventory levels..."
variants = ProductVariant.all.to_a
variants.each do |variant|
  reorder_point = rand(5..15)

  stock_quantity = case rand(100)
  when 0..9
    0
  when 10..24
    rand(1..reorder_point)
  else
    rand(20..120)
  end

  variant.update!(
    reorder_point: reorder_point,
    reorder_quantity: rand(25..75),
    track_inventory: true,
    stock_quantity: stock_quantity
  )
end

puts "Creating additional customers for reviews..."
review_customers_data = [
  { email: 'aanya@example.com', first_name: 'Aanya', last_name: 'Shah' },
  { email: 'arjun@example.com', first_name: 'Arjun', last_name: 'Mehta' },
  { email: 'ishita@example.com', first_name: 'Ishita', last_name: 'Verma' },
  { email: 'kabir@example.com', first_name: 'Kabir', last_name: 'Singh' },
  { email: 'meera@example.com', first_name: 'Meera', last_name: 'Iyer' }
]

review_customers = review_customers_data.map do |data|
  Customer.find_or_create_by!(email: data[:email]) do |c|
    c.first_name = data[:first_name]
    c.last_name = data[:last_name]
    c.password = 'password123'
    c.phone = "555-#{rand(100..999)}-#{rand(1000..9999)}"
    c.active = true
  end
end

puts "Creating demo addresses..."
demo_shipping = Address.find_or_create_by!(customer: demo_customer, address_type: 'shipping') do |a|
  a.first_name = demo_customer.first_name
  a.last_name = demo_customer.last_name
  a.phone = demo_customer.phone
  a.street_address = 'N2-1501 Omkar Royal Nest Tower'
  a.apartment = ''
  a.city = 'Noida'
  a.state = 'UP'
  a.postal_code = '201318'
  a.country = 'India'
  a.is_default = true
end

demo_billing = Address.find_or_create_by!(customer: demo_customer, address_type: 'billing') do |a|
  a.first_name = demo_customer.first_name
  a.last_name = demo_customer.last_name
  a.phone = demo_customer.phone
  a.street_address = 'N2-1501 Omkar Royal Nest Tower'
  a.apartment = ''
  a.city = 'Noida'
  a.state = 'UP'
  a.postal_code = '201318'
  a.country = 'India'
  a.is_default = true
end

puts "Creating product reviews..."
review_titles = [
  'Beautiful quality',
  'Worth the price',
  'Great packaging',
  'Loved it',
  'Superb finish',
  'Exceeded expectations'
]

review_bodies = [
  'Quality feels premium and the finish is excellent.',
  'Arrived on time and looks even better in person.',
  'The product matched the photos. Very happy with the purchase.',
  'Good value for money. Would recommend.',
  'Customer support was helpful and delivery was smooth.'
]

Product.find_each do |product|
  next if product.reviews.exists?

  rand(3..9).times do
    customer = review_customers.sample
    review = Review.create!(
      product: product,
      customer: customer,
      rating: rand(3..5),
      title: review_titles.sample,
      body: review_bodies.sample,
      approved: true,
      approved_at: Time.current
    )
    review.send(:update_product_rating)
  end
end

puts "Creating demo orders for demo customer..."
if demo_customer.orders.none?
  available_variants = ProductVariant.active.where("stock_quantity > 0").to_a

  4.times do
    order = Order.create!(
      customer: demo_customer,
      shipping_address: demo_shipping,
      billing_address: demo_billing,
      status: 'pending',
      payment_status: 'pending',
      payment_method: 'cod',
      is_draft: true,
      shipping_amount: 0,
      tax_amount: 0
    )

    order_variants = available_variants.sample(rand(1..3))
    order_variants.each do |variant|
      quantity = [1, 1, 1, 2, 2, 3].sample
      order.order_items.create!(
        product_variant: variant,
        product_name: variant.product.name,
        variant_name: variant.name,
        sku: variant.sku,
        quantity: quantity,
        unit_price: variant.price
      )
    end

    order.calculate_totals!
    order.save!
    order.place!

    if [true, true, false].sample
      order.ship!
      order.deliver!

      order.order_items.each do |item|
        next unless item.product_variant

        Review.find_or_create_by!(product: item.product_variant.product, order: order) do |r|
          r.customer = demo_customer
          r.rating = rand(3..5)
          r.title = review_titles.sample
          r.body = review_bodies.sample
          r.approved = true
          r.approved_at = Time.current
        end
      end
    end
  end
end

puts "Seeds completed!"
puts ""
puts "Admin Login:"
puts "  Email: admin@noralooks.com"
puts "  Password: password123"
puts ""
puts "Demo Customer Login:"
puts "  Email: demo@example.com"
puts "  Password: password123"
