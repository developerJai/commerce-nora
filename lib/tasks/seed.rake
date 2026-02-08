namespace :seed do
  desc "Section 1: Seed homepage essentials — admin, categories, banners, homepage collections, coupons"
  task homepage: :environment do
    puts "=" * 60
    puts "SECTION 1: Homepage & Essentials"
    puts "=" * 60

    # ── Admin User ──
    puts "\n→ Creating admin user..."
    AdminUser.find_or_create_by!(email: "admin@noralooks.com") do |admin|
      admin.name = "Admin User"
      admin.password = "password123"
      admin.active = true
    end
    puts "  ✓ Admin: admin@noralooks.com / password123 (role: admin)"

    # ── Categories (Jewellery-focused) ──
    puts "\n→ Creating categories..."
    categories_data = [
      { name: "Necklaces",   slug: "necklaces",   description: "Elegant necklaces and pendant sets for every occasion",  position: 0 },
      { name: "Rings",       slug: "rings",        description: "Diamond, gold and gemstone rings",                       position: 1 },
      { name: "Earrings",    slug: "earrings",     description: "Studs, jhumkas, drops and hoops",                        position: 2 },
      { name: "Bangles",     slug: "bangles",      description: "Gold, diamond and gemstone bangles",                     position: 3 },
      { name: "Bracelets",   slug: "bracelets",    description: "Chain bracelets, charm bracelets and cuffs",             position: 4 },
      { name: "Pendants",    slug: "pendants",     description: "Solitaire, religious and everyday pendants",             position: 5 }
    ]

    categories_data.each do |cat|
      Category.find_or_create_by!(slug: cat[:slug]) do |c|
        c.name = cat[:name]
        c.description = cat[:description]
        c.active = true
        c.position = cat[:position]
      end
    end
    puts "  ✓ #{categories_data.size} categories created"

    # ── Banners ──
    puts "\n→ Creating banners..."
    banners_data = [
      { title: "New Collection 2026",       subtitle: "Discover our latest handcrafted designs",         link_url: "/products?sort=newest", position: 0 },
      { title: "Flat 30% Off Making Charges", subtitle: "On all gold jewellery — limited time offer",   link_url: "/products",             position: 1 },
      { title: "Wedding Season Special",    subtitle: "Bridal sets, mangalsutra & complete trousseau",   link_url: "/categories/necklaces", position: 2 }
    ]

    banners_data.each do |b|
      Banner.find_or_create_by!(title: b[:title]) do |banner|
        banner.subtitle = b[:subtitle]
        banner.link_url = b[:link_url]
        banner.active = true
        banner.position = b[:position]
      end
    end
    puts "  ✓ #{banners_data.size} banners created"

    # ── Homepage Collections ──
    puts "\n→ Creating homepage collections..."

    # Collection 1: Promotional offers (4-column grid like the 30% off cards)
    offers = HomepageCollection.find_or_create_by!(name: "Special Offers") do |c|
      c.subtitle = "Exclusive deals handpicked for you"
      c.layout_type = "grid_4"
      c.position = 0
      c.active = true
    end

    offers_items = [
      { title: "Diamond Jewellery",  subtitle: "1900+ Unique designs",  badge_text: "UP TO 30% OFF", link_url: "/products?featured=true", position: 0 },
      { title: "Gold Jewellery",     subtitle: "4900+ Unique designs",  badge_text: "UP TO 30% OFF", link_url: "/categories/necklaces",   position: 1 },
      { title: "Gemstone Jewellery", subtitle: "650+ Unique designs",   badge_text: "UP TO 30% OFF", link_url: "/categories/rings",       position: 2 },
      { title: "Uncut Jewellery",    subtitle: "480+ Unique designs",   badge_text: "UP TO 30% OFF", link_url: "/categories/earrings",    position: 3 }
    ]

    offers_items.each do |item_data|
      offers.items.find_or_create_by!(title: item_data[:title]) do |item|
        item.subtitle = item_data[:subtitle]
        item.badge_text = item_data[:badge_text]
        item.link_url = item_data[:link_url]
        item.position = item_data[:position]
        item.overlay_position = "bottom_left"
      end
    end
    puts "  ✓ 'Special Offers' collection (grid_4) with #{offers_items.size} items"

    # Collection 2: Seasonal/thematic (bento grid like Valentine's Special)
    seasonal = HomepageCollection.find_or_create_by!(name: "Valentine's Special") do |c|
      c.subtitle = "Gifts that speak the language of love"
      c.layout_type = "bento"
      c.position = 1
      c.active = true
    end

    seasonal_items = [
      { title: "Crafted For Love That Lasts Forever",  subtitle: "Express your emotions beautifully with our jewellery collection", link_url: "/products?featured=true", position: 0, overlay_position: "bottom_left" },
      { title: "Endless Bond",          subtitle: "Starting from ₹11,500",  link_url: "/categories/pendants",  position: 1, overlay_position: "center" },
      { title: "Love Alphabet",         subtitle: "Starting from ₹13,118",  link_url: "/categories/rings",     position: 2, overlay_position: "center" },
      { title: "Encircled Love",        subtitle: "Starting from ₹10,300",  link_url: "/categories/bracelets", position: 3, overlay_position: "center" },
      { title: "Daily Wear",            subtitle: "Starting from ₹11,307",  link_url: "/categories/earrings",  position: 4, overlay_position: "center" }
    ]

    seasonal_items.each do |item_data|
      seasonal.items.find_or_create_by!(title: item_data[:title]) do |item|
        item.subtitle = item_data[:subtitle]
        item.link_url = item_data[:link_url]
        item.position = item_data[:position]
        item.overlay_position = item_data[:overlay_position]
      end
    end
    puts "  ✓ 'Valentine's Special' collection (bento) with #{seasonal_items.size} items"

    # Collection 3: Handpicked (asymmetric layout)
    handpicked = HomepageCollection.find_or_create_by!(name: "Handpicked Just For You!") do |c|
      c.subtitle = "Our lightweight collection keeps you stylish and comfortable from dawn to dusk"
      c.layout_type = "asymmetric"
      c.position = 2
      c.active = true
    end

    handpicked_items = [
      { title: "Statement Necklace Sets", link_url: "/categories/necklaces", position: 0, overlay_position: "center" },
      { title: "Lightweight Jewellery",   link_url: "/products",             position: 1, overlay_position: "center" },
      { title: "Stylist Earrings",        link_url: "/categories/earrings",  position: 2, overlay_position: "bottom_center" }
    ]

    handpicked_items.each do |item_data|
      handpicked.items.find_or_create_by!(title: item_data[:title]) do |item|
        item.link_url = item_data[:link_url]
        item.position = item_data[:position]
        item.overlay_position = item_data[:overlay_position]
      end
    end
    puts "  ✓ 'Handpicked Just For You!' collection (asymmetric) with #{handpicked_items.size} items"

    # Collection 4: Category showcase (4-column grid like Gemstone Jewellery)
    gemstone = HomepageCollection.find_or_create_by!(name: "Gemstone Jewellery") do |c|
      c.subtitle = "Capturing timeless grace in each precious stone"
      c.layout_type = "grid_4"
      c.position = 3
      c.active = true
    end

    gemstone_items = [
      { title: "Necklaces", link_url: "/categories/necklaces", position: 0, overlay_position: "bottom_center" },
      { title: "Rings",     link_url: "/categories/rings",     position: 1, overlay_position: "bottom_center" },
      { title: "Earrings",  link_url: "/categories/earrings",  position: 2, overlay_position: "bottom_center" },
      { title: "Bangles",   link_url: "/categories/bangles",   position: 3, overlay_position: "bottom_center" }
    ]

    gemstone_items.each do |item_data|
      gemstone.items.find_or_create_by!(title: item_data[:title]) do |item|
        item.link_url = item_data[:link_url]
        item.position = item_data[:position]
        item.overlay_position = item_data[:overlay_position]
      end
    end
    puts "  ✓ 'Gemstone Jewellery' collection (grid_4) with #{gemstone_items.size} items"

    # ── Coupons ──
    puts "\n→ Creating coupons..."
    Coupon.find_or_create_by!(code: "WELCOME10") do |c|
      c.name = "Welcome Discount"
      c.description = "10% off your first order"
      c.discount_type = "percentage"
      c.discount_value = 10
      c.minimum_order_amount = 50
      c.active = true
    end

    Coupon.find_or_create_by!(code: "SAVE20") do |c|
      c.name = "Save ₹20"
      c.description = "₹20 off orders over ₹100"
      c.discount_type = "fixed"
      c.discount_value = 20
      c.minimum_order_amount = 100
      c.active = true
    end
    puts "  ✓ 2 coupons created"

    puts "\n✅ Section 1 complete!"
    puts "   → Login at /admin with: admin@noralooks.com / password123"
    puts "   → Homepage collections need images — upload them at /admin/homepage_collections"
  end

  # ─────────────────────────────────────────────────────────────

  desc "Seed HSN codes for tax classification"
  task hsn_codes: :environment do
    puts "\n→ Creating HSN codes..."
    hsn_data = [
      { code: "7113", description: "Articles of jewellery and parts thereof, of precious metal", gst_rate: 3.0, category_name: "Jewellery" },
      { code: "71131100", description: "Articles of jewellery of silver", gst_rate: 3.0, category_name: "Jewellery" },
      { code: "71131900", description: "Articles of jewellery of other precious metal", gst_rate: 3.0, category_name: "Jewellery" },
      { code: "7117", description: "Imitation jewellery", gst_rate: 3.0, category_name: "Imitation Jewellery" },
      { code: "7114", description: "Articles of goldsmiths' or silversmiths' wares", gst_rate: 3.0, category_name: "Precious Metal Wares" },
      { code: "7116", description: "Articles of natural or cultured pearls, precious or semi-precious stones", gst_rate: 3.0, category_name: "Gemstones" },
      { code: "4819", description: "Packaging boxes, cartons and cases of paper or paperboard", gst_rate: 18.0, category_name: "Packaging" },
      { code: "7101", description: "Pearls, natural or cultured", gst_rate: 3.0, category_name: "Gemstones" }
    ]

    hsn_data.each do |data|
      HsnCode.find_or_create_by!(code: data[:code]) do |h|
        h.description = data[:description]
        h.gst_rate = data[:gst_rate]
        h.category_name = data[:category_name]
        h.active = true
      end
    end
    puts "  ✓ #{hsn_data.size} HSN codes created"
  end

  # ─────────────────────────────────────────────────────────────

  desc "Seed sample vendors with login credentials"
  task vendors: :environment do
    puts "\n→ Creating vendors..."

    default_hsn = HsnCode.find_by(code: "7113")

    vendors_data = [
      {
        business_name: "Laxmi Gold House",
        contact_name: "Rajesh Kumar",
        email: "vendor1@noralooks.com",
        phone: "9876543210",
        gst_number: "07AABCT1332L1ZH",
        city: "Jaipur", state: "Rajasthan", pincode: "302001",
        password: "password123"
      },
      {
        business_name: "Shree Diamonds",
        contact_name: "Priya Sharma",
        email: "vendor2@noralooks.com",
        phone: "9876543211",
        gst_number: "27AADCS0472N1ZG",
        city: "Mumbai", state: "Maharashtra", pincode: "400001",
        password: "password123"
      },
      {
        business_name: "Royal Gems & Jewels",
        contact_name: "Amit Patel",
        email: "vendor3@noralooks.com",
        phone: "9876543212",
        gst_number: "24AAECR5055K1ZB",
        city: "Surat", state: "Gujarat", pincode: "395001",
        password: "password123"
      }
    ]

    vendors_data.each do |vdata|
      vendor = Vendor.find_or_create_by!(email: vdata[:email]) do |v|
        v.business_name = vdata[:business_name]
        v.contact_name = vdata[:contact_name]
        v.phone = vdata[:phone]
        v.gst_number = vdata[:gst_number]
        v.city = vdata[:city]
        v.state = vdata[:state]
        v.pincode = vdata[:pincode]
        v.active = true
      end

      AdminUser.find_or_create_by!(email: vdata[:email]) do |admin|
        admin.name = vdata[:contact_name]
        admin.password = vdata[:password]
        admin.role = "vendor"
        admin.vendor = vendor
        admin.active = true
      end

      puts "  ✓ #{vdata[:business_name]}: #{vdata[:email]} / #{vdata[:password]}"
    end

    puts "  ✓ #{vendors_data.size} vendors created"
  end

  # ─────────────────────────────────────────────────────────────

  desc "Section 2: Seed products and variants"
  task products: :environment do
    puts "=" * 60
    puts "SECTION 2: Products & Variants"
    puts "=" * 60

    categories = Category.active.ordered.to_a
    if categories.empty?
      puts "⚠ No categories found. Run `rails seed:homepage` first."
      next
    end

    # ── Hand-crafted products ──
    puts "\n→ Creating curated products..."
    necklaces  = Category.find_by(slug: "necklaces")
    rings      = Category.find_by(slug: "rings")
    earrings   = Category.find_by(slug: "earrings")
    bangles    = Category.find_by(slug: "bangles")
    bracelets  = Category.find_by(slug: "bracelets")
    pendants   = Category.find_by(slug: "pendants")

    # Vendor and HSN assignment
    vendors = Vendor.active.to_a
    default_hsn = HsnCode.find_by(code: "7113")
    target_vendor_id = ENV['VENDOR_ID'] ? ENV['VENDOR_ID'].to_i : nil

    products_data = [
      {
        name: "Royal Diamond Necklace Set", slug: "royal-diamond-necklace-set",
        description: "A breathtaking diamond necklace set featuring brilliant-cut diamonds in 18K gold. Perfect for weddings and grand occasions.",
        short_description: "18K gold diamond necklace set",
        category: necklaces, price: 85_999.00, featured: true,
        variants: [
          { name: "18K Yellow Gold",    price: 85_999.00, compare_at_price: 95_999.00, stock_quantity: 8 },
          { name: "18K Rose Gold",      price: 87_999.00, compare_at_price: 97_999.00, stock_quantity: 5 },
          { name: "18K White Gold",     price: 89_999.00, stock_quantity: 3 }
        ]
      },
      {
        name: "Emerald Solitaire Ring", slug: "emerald-solitaire-ring",
        description: "Natural emerald solitaire ring set in 14K gold with diamond side stones. A timeless piece of elegance.",
        short_description: "14K gold emerald solitaire ring",
        category: rings, price: 42_500.00, featured: true,
        variants: [
          { name: "Size 6",  price: 42_500.00, compare_at_price: 49_999.00, stock_quantity: 12 },
          { name: "Size 7",  price: 42_500.00, compare_at_price: 49_999.00, stock_quantity: 15 },
          { name: "Size 8",  price: 42_500.00, stock_quantity: 10 },
          { name: "Size 9",  price: 44_000.00, stock_quantity: 8 }
        ]
      },
      {
        name: "Temple Gold Jhumka Earrings", slug: "temple-gold-jhumka-earrings",
        description: "Traditional temple-inspired jhumka earrings in 22K gold with intricate detailing. A statement piece for festive wear.",
        short_description: "22K gold temple jhumka earrings",
        category: earrings, price: 35_800.00, featured: true,
        variants: [
          { name: "Small",   price: 35_800.00, stock_quantity: 20 },
          { name: "Medium",  price: 42_200.00, stock_quantity: 15 },
          { name: "Large",   price: 48_600.00, compare_at_price: 52_000.00, stock_quantity: 10 }
        ]
      },
      {
        name: "Diamond Studded Gold Bangle", slug: "diamond-studded-gold-bangle",
        description: "Exquisite 18K gold bangle studded with round brilliant diamonds. Wear alone or stack for a luxurious look.",
        short_description: "18K gold diamond-studded bangle",
        category: bangles, price: 67_500.00, featured: true,
        variants: [
          { name: "2.4 inches", price: 67_500.00, compare_at_price: 75_000.00, stock_quantity: 10 },
          { name: "2.6 inches", price: 67_500.00, compare_at_price: 75_000.00, stock_quantity: 12 },
          { name: "2.8 inches", price: 69_000.00, stock_quantity: 8 }
        ]
      },
      {
        name: "Rose Gold Chain Bracelet", slug: "rose-gold-chain-bracelet",
        description: "Delicate rose gold chain bracelet with a heart-shaped charm. Ideal for everyday wear and gifting.",
        short_description: "Rose gold heart charm bracelet",
        category: bracelets, price: 11_300.00, featured: true,
        variants: [
          { name: "6.5 inches", price: 11_300.00, stock_quantity: 30 },
          { name: "7 inches",   price: 11_300.00, stock_quantity: 35 },
          { name: "7.5 inches", price: 11_800.00, stock_quantity: 25 }
        ]
      },
      {
        name: "Solitaire Diamond Pendant", slug: "solitaire-diamond-pendant",
        description: "Classic solitaire diamond pendant in 18K white gold. The perfect everyday luxury.",
        short_description: "18K white gold solitaire pendant",
        category: pendants, price: 28_900.00, featured: true,
        variants: [
          { name: "0.25 Carat", price: 28_900.00, stock_quantity: 20 },
          { name: "0.50 Carat", price: 52_000.00, compare_at_price: 58_000.00, stock_quantity: 12 },
          { name: "1.00 Carat", price: 98_000.00, stock_quantity: 5 }
        ]
      },
      {
        name: "Pearl Drop Earrings", slug: "pearl-drop-earrings",
        description: "Elegant freshwater pearl drop earrings with 14K gold hooks. Effortless sophistication for any outfit.",
        short_description: "14K gold pearl drop earrings",
        category: earrings, price: 8_750.00, featured: false,
        variants: [
          { name: "White Pearl",  price: 8_750.00, stock_quantity: 40 },
          { name: "Pink Pearl",   price: 9_200.00, stock_quantity: 25 },
          { name: "Black Pearl",  price: 10_500.00, compare_at_price: 12_000.00, stock_quantity: 15 }
        ]
      },
      {
        name: "Gold Mangalsutra Chain", slug: "gold-mangalsutra-chain",
        description: "Traditional 22K gold mangalsutra with black bead chain and diamond pendant. A symbol of eternal love.",
        short_description: "22K gold diamond mangalsutra",
        category: necklaces, price: 45_600.00, featured: true,
        variants: [
          { name: "16 inches", price: 45_600.00, stock_quantity: 18 },
          { name: "18 inches", price: 47_800.00, stock_quantity: 22 },
          { name: "20 inches", price: 50_000.00, stock_quantity: 10 }
        ]
      }
    ]

    products_data.each_with_index do |pdata, pidx|
      product = Product.find_or_create_by!(slug: pdata[:slug]) do |p|
        p.name = pdata[:name]
        p.description = pdata[:description]
        p.short_description = pdata[:short_description]
        p.category = pdata[:category]
        p.price = pdata[:price]
        p.active = true
        p.featured = pdata[:featured]
        p.hsn_code = default_hsn
        p.vendor_id = target_vendor_id || (vendors.any? ? vendors[pidx % vendors.size].id : nil)
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
    puts "  ✓ #{products_data.size} curated products with variants"

    # ── Bulk products for catalogue / infinite scroll ──
    puts "\n→ Creating bulk catalogue products..."

    adjectives = %w[Classic Modern Minimal Elegant Premium Vintage Sleek Bold Soft Matte Glossy Refined Timeless Everyday Limited Signature Luxe]
    nouns      = %w[Necklace Ring Bracelet Earrings Pendant Chain Bangle Charm Stud Hoops Anklet]
    materials  = %w[Gold Silver RoseGold Platinum Diamond Pearl Crystal Ruby Emerald Sapphire]

    target_products = 320
    existing_seeded = Product.where("slug LIKE ?", "seed-%").count
    to_create = [target_products - existing_seeded, 0].max

    if to_create > 0
      to_create.times do |i|
        idx = existing_seeded + i + 1
        category = categories[idx % categories.size]

        name = "#{adjectives[idx % adjectives.size]} #{materials[idx % materials.size]} #{nouns[idx % nouns.size]}"
        slug = "seed-#{idx}-#{name.parameterize}"

        base_price = (1500 + (idx % 25_000)).round(2)
        featured = (idx % 11 == 0)

        product = Product.find_or_create_by!(slug: slug) do |p|
          p.name = name
          p.description = "#{name} — designed for everyday elegance with premium finishing and luxurious comfort."
          p.short_description = "#{adjectives[idx % adjectives.size]} #{nouns[idx % nouns.size].downcase}"
          p.category = category
          p.price = base_price
          p.active = true
          p.featured = featured
          p.hsn_code = default_hsn
          p.vendor_id = target_vendor_id || (vendors.any? ? vendors[idx % vendors.size].id : nil)
        end

        variant_count = 2 + (idx % 2)
        (1..variant_count).each do |n|
          vname = "Option #{n}"
          ProductVariant.find_or_create_by!(product: product, name: vname) do |v|
            v.sku = "#{slug.upcase.gsub('-', '')}-#{n}"
            v.price = base_price + ((n - 1) * 500)
            v.compare_at_price = (n == 1 && idx % 5 == 0) ? (base_price + 1500) : nil
            v.stock_quantity = 20 + (idx % 80)
            v.active = true
            v.position = n - 1
          end
        end
      end
      puts "  ✓ #{to_create} bulk products created"
    else
      puts "  ✓ #{target_products} bulk products already exist — skipped"
    end

    # ── Inventory levels ──
    puts "\n→ Setting inventory levels..."
    srand(1234)
    ProductVariant.find_each do |variant|
      reorder_point = rand(5..15)

      stock_quantity = case rand(100)
      when 0..9   then 0
      when 10..24 then rand(1..reorder_point)
      else rand(20..120)
      end

      variant.update_columns(
        reorder_point: reorder_point,
        reorder_quantity: rand(25..75),
        track_inventory: true,
        stock_quantity: stock_quantity
      )
    end
    puts "  ✓ Inventory levels set for all variants"

    puts "\n✅ Section 2 complete! #{Product.count} products, #{ProductVariant.count} variants in catalogue."
  end

  # ─────────────────────────────────────────────────────────────

  desc "Section 3: Seed customers, orders, reviews and ratings"
  task orders: :environment do
    puts "=" * 60
    puts "SECTION 3: Customers, Orders & Reviews"
    puts "=" * 60

    if Product.count == 0
      puts "⚠ No products found. Run `rails seed:products` first."
      next
    end

    srand(1234)

    # ── Demo customer ──
    puts "\n→ Creating demo customer..."
    demo_customer = Customer.find_or_create_by!(email: "demo@example.com") do |c|
      c.first_name = "Demo"
      c.last_name = "User"
      c.password = "password123"
      c.phone = "555-123-4567"
      c.active = true
    end
    puts "  ✓ Demo customer: demo@example.com / password123"

    # ── Review customers ──
    puts "\n→ Creating review customers..."
    review_customers_data = [
      { email: "aanya@example.com",  first_name: "Aanya",  last_name: "Shah" },
      { email: "arjun@example.com",  first_name: "Arjun",  last_name: "Mehta" },
      { email: "ishita@example.com", first_name: "Ishita", last_name: "Verma" },
      { email: "kabir@example.com",  first_name: "Kabir",  last_name: "Singh" },
      { email: "meera@example.com",  first_name: "Meera",  last_name: "Iyer" },
      { email: "priya@example.com",  first_name: "Priya",  last_name: "Nair" },
      { email: "rohan@example.com",  first_name: "Rohan",  last_name: "Gupta" }
    ]

    review_customers = review_customers_data.map do |data|
      Customer.find_or_create_by!(email: data[:email]) do |c|
        c.first_name = data[:first_name]
        c.last_name = data[:last_name]
        c.password = "password123"
        c.phone = "555-#{rand(100..999)}-#{rand(1000..9999)}"
        c.active = true
      end
    end
    puts "  ✓ #{review_customers.size} review customers"

    # ── Demo addresses ──
    puts "\n→ Creating addresses..."
    demo_shipping = Address.find_or_create_by!(customer: demo_customer, address_type: "shipping") do |a|
      a.first_name = demo_customer.first_name
      a.last_name = demo_customer.last_name
      a.phone = demo_customer.phone
      a.street_address = "N2-1501 Omkar Royal Nest Tower"
      a.apartment = ""
      a.city = "Noida"
      a.state = "UP"
      a.postal_code = "201318"
      a.country = "India"
      a.is_default = true
    end

    demo_billing = Address.find_or_create_by!(customer: demo_customer, address_type: "billing") do |a|
      a.first_name = demo_customer.first_name
      a.last_name = demo_customer.last_name
      a.phone = demo_customer.phone
      a.street_address = "N2-1501 Omkar Royal Nest Tower"
      a.apartment = ""
      a.city = "Noida"
      a.state = "UP"
      a.postal_code = "201318"
      a.country = "India"
      a.is_default = true
    end
    puts "  ✓ Shipping and billing addresses"

    # ── Product Reviews ──
    puts "\n→ Creating product reviews..."
    review_titles = [
      "Beautiful quality", "Worth the price", "Great packaging",
      "Loved it", "Superb finish", "Exceeded expectations",
      "Stunning piece", "Perfect gift", "Absolutely gorgeous"
    ]

    review_bodies = [
      "Quality feels premium and the finish is excellent. Would buy again.",
      "Arrived on time and looks even better in person. My wife loved it.",
      "The product matched the photos. Very happy with the purchase.",
      "Good value for money. Would recommend to friends and family.",
      "Customer support was helpful and delivery was smooth.",
      "The craftsmanship is impeccable. You can see the attention to detail.",
      "Wore it to a wedding and got so many compliments!",
      "Packaging was beautiful — felt like a real luxury experience."
    ]

    review_count = 0
    Product.find_each do |product|
      next if product.reviews.exists?

      rand(3..9).times do
        customer = review_customers.sample
        Review.create!(
          product: product,
          customer: customer,
          rating: [3, 4, 4, 4, 5, 5, 5].sample,
          title: review_titles.sample,
          body: review_bodies.sample,
          approved: true,
          approved_at: Time.current
        )
        review_count += 1
      end
      product.update_rating!
    end
    puts "  ✓ #{review_count} reviews created across #{Product.count} products"

    # ── Demo Orders ──
    puts "\n→ Creating demo orders..."
    if demo_customer.orders.none?
      available_variants = ProductVariant.active.where("stock_quantity > 0").to_a

      4.times do |n|
        order = Order.create!(
          customer: demo_customer,
          shipping_address: demo_shipping,
          billing_address: demo_billing,
          status: "pending",
          payment_status: "pending",
          payment_method: "cod",
          is_draft: true,
          shipping_amount: 0,
          tax_amount: 0
        )

        order_variants = available_variants.sample(rand(1..3))
        order_vendor_id = order_variants.first&.product&.vendor_id
        order.vendor_id = order_vendor_id

        order_variants.each do |variant|
          quantity = [1, 1, 1, 2, 2, 3].sample
          order.order_items.create!(
            product_variant: variant,
            vendor_id: variant.product.vendor_id,
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

        # Deliver some orders so we have variety
        if [true, true, false].sample
          order.update_columns(
            status: "shipped",
            shipped_at: Time.current - rand(1..5).days,
            shipper_name: "BlueDart Express",
            shipping_carrier: "BlueDart",
            tracking_number: "BD#{SecureRandom.hex(6).upcase}"
          )
          order.deliver!

          # Add order-specific reviews
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
      puts "  ✓ 4 demo orders created"
    else
      puts "  ✓ Demo orders already exist — skipped"
    end

    puts "\n✅ Section 3 complete!"
    puts "   → #{Customer.count} customers, #{Order.count} orders, #{Review.count} reviews"
  end

  # ─────────────────────────────────────────────────────────────

  desc "Run all seed sections in order (homepage → hsn_codes → vendors → products → orders)"
  task all: :environment do
    Rake::Task["seed:homepage"].invoke
    Rake::Task["seed:hsn_codes"].invoke
    Rake::Task["seed:vendors"].invoke
    Rake::Task["seed:products"].invoke
    Rake::Task["seed:orders"].invoke

    puts ""
    puts "=" * 60
    puts "ALL SEEDS COMPLETE"
    puts "=" * 60
    puts ""
    puts "Admin:    admin@noralooks.com / password123"
    puts "Vendor 1: vendor1@noralooks.com / password123 (Laxmi Gold House)"
    puts "Vendor 2: vendor2@noralooks.com / password123 (Shree Diamonds)"
    puts "Vendor 3: vendor3@noralooks.com / password123 (Royal Gems & Jewels)"
    puts "Customer: demo@example.com / password123"
    puts ""
    puts "Next steps:"
    puts "  1. Start the server:  bin/dev"
    puts "  2. Admin panel: /admin/login"
    puts "  3. Vendor portal: /vendor/login"
    puts "  4. Upload images to homepage collections at /admin/homepage_collections"
    puts "  5. Upload product images at /admin/products"
    puts ""
  end
end
