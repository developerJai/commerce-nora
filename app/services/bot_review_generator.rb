class BotReviewGenerator
  # Extra bot customer names to create on demand
  BOT_NAMES = [
    { first: "Priya", last: "Sharma" },
    { first: "Anita", last: "Verma" },
    { first: "Pooja", last: "Gupta" },
    { first: "Neha", last: "Singh" },
    { first: "Sunita", last: "Yadav" },
    { first: "Rekha", last: "Patel" },
    { first: "Meena", last: "Joshi" },
    { first: "Seema", last: "Kumar" },
    { first: "Renu", last: "Mishra" },
    { first: "Kavita", last: "Reddy" },
    { first: "Suman", last: "Das" },
    { first: "Geeta", last: "Nair" },
    { first: "Asha", last: "Jain" },
    { first: "Lata", last: "Pandey" },
    { first: "Rani", last: "Kaur" },
    { first: "Deepa", last: "Shah" },
    { first: "Nisha", last: "Rao" },
    { first: "Mona", last: "Tiwari" },
    { first: "Reena", last: "Dubey" },
    { first: "Sita", last: "Chauhan" },
    { first: "Ritu", last: "Agarwal" },
    { first: "Sapna", last: "Kapoor" },
    { first: "Kiran", last: "Malik" },
    { first: "Jaya", last: "Saxena" },
    { first: "Usha", last: "Bhatt" },
  ].freeze

  # Reviews grouped by rating - varied lengths, natural Indian English
  REVIEW_TEMPLATES = {
    5 => [
      -> (p) { "Loved it! #{p} looks exactly like the photo." },
      -> (p) { "Very happy with my purchase. Quality is amazing for the price." },
      -> (p) { "Got so many compliments at a wedding last week. Totally worth it." },
      -> (p) { "Beautiful piece. Packaging was also really nice." },
      -> (p) { "Ordered for my sister's birthday and she absolutely loved it!" },
      -> (p) { "Superb quality. I was not expecting this at such a low price honestly." },
      -> (p) { "This is my 3rd order from here. Never disappoints." },
      -> (p) { "The #{p} is stunning. Wore it to office and everyone asked where I got it from." },
      -> (p) { "Perfect gift for my mom. She was so happy." },
      -> (p) { "Fast delivery and product is really good." },
      -> (p) { "Bought this for a puja and it looked so elegant. Happy customer!" },
      -> (p) { "Really nice #{p.downcase}. Color is exactly as shown." },
      -> (p) { "Excellent! Will definitely order more." },
      -> (p) { "Best jewellery I have bought online. No complaints at all." },
      -> (p) { "Wore it for 8 hours straight, no irritation. Very comfortable." },
      -> (p) { "This #{p.downcase} is gorgeous, my friends thought its real gold lol" },
      -> (p) { "Diwali shopping done from here this year. Love the collection." },
      -> (p) { "Got it within 2 days. Fits perfectly and looks premium." },
    ],
    4 => [
      -> (p) { "Nice product. Slightly different shade than photo but still looks good." },
      -> (p) { "Good quality #{p.downcase}. Could have been packed a bit better though." },
      -> (p) { "Liked it overall. The clasp is a bit tight but manageable." },
      -> (p) { "Pretty piece. Delivery took one extra day but product is fine." },
      -> (p) { "Value for money. Would recommend to friends." },
      -> (p) { "Bought for daily wear. Holding up well after a few weeks." },
      -> (p) { "Decent product, matches well with traditional outfits." },
      -> (p) { "#{p} is good. Expected slightly heavier but looks nice." },
      -> (p) { "Happy with the purchase. Color could be slightly brighter." },
      -> (p) { "Gifted to my friend, she said it's really nice." },
      -> (p) { "Good product for the price range. No issues so far." },
      -> (p) { "Looks elegant. Only wish it came with a box." },
      -> (p) { "One of the better artificial jewellery pieces I have bought." },
    ],
    3 => [
      -> (p) { "Average product. OK for the price." },
      -> (p) { "It's decent, nothing too special." },
      -> (p) { "#{p} is fine. Expected better finishing." },
      -> (p) { "Looks alright. Not sure how long it will last." },
      -> (p) { "Color is a bit different from the picture. Acceptable though." },
    ]
  }.freeze

  # Optional short titles
  TITLES = {
    5 => ["Love it!", "Amazing!", "Best purchase", "So pretty", "Highly recommend", "Worth every rupee", nil, nil, nil],
    4 => ["Good product", "Nice one", "Happy with it", "Pretty good", nil, nil, nil, nil],
    3 => ["OK", "Decent", "Average", nil, nil, nil]
  }.freeze

  def initialize(product)
    @product = product
  end

  def generate(count)
    # Find bot customers who haven't reviewed this product yet
    existing_reviewer_ids = @product.reviews.where(customer_id: Customer.bots.select(:id)).pluck(:customer_id)
    eligible = Customer.bots.where.not(id: existing_reviewer_ids).to_a

    # Create more bot customers if we don't have enough eligible ones
    if eligible.size < count
      shortage = count - eligible.size
      eligible += create_new_bot_customers(shortage)
    end

    created = 0
    used_days = []
    eligible.sample(count).each do |customer|
      rating = weighted_random_rating
      templates = REVIEW_TEMPLATES[rating]
      body = templates.sample.call(@product.name)
      title = TITLES[rating].sample

      # Random date within last 90 days, ensure each review is on a different day
      days_ago = rand(5..90)
      days_ago = rand(5..90) while used_days.include?(days_ago)
      used_days << days_ago
      review_date = days_ago.days.ago + rand(6..22).hours + rand(0..59).minutes

      @product.reviews.create!(
        customer: customer,
        rating: rating,
        title: title,
        body: body,
        approved: true,
        approved_at: review_date,
        created_at: review_date,
        updated_at: review_date
      )
      created += 1
    end

    created
  end

  private

  def weighted_random_rating
    # Weighted towards 4 and 5 stars (realistic distribution)
    roll = rand(100)
    if roll < 50
      5
    elsif roll < 85
      4
    else
      3
    end
  end

  def create_new_bot_customers(needed)
    used_emails = Customer.bots.pluck(:email)
    available_names = BOT_NAMES.reject { |n| used_emails.include?("#{n[:first].downcase}.#{n[:last].downcase}@noralooks.bot") }

    new_customers = []
    available_names.first(needed).each do |name|
      customer = Customer.create!(
        first_name: name[:first],
        last_name: name[:last],
        email: "#{name[:first].downcase}.#{name[:last].downcase}@noralooks.bot",
        password: SecureRandom.hex(16),
        is_bot: true,
        active: true
      )
      new_customers << customer
    end

    new_customers
  end
end
