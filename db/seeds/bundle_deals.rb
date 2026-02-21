# Seed data for Bundle Deals
puts "Creating bundle deals..."

BundleDeal.find_or_create_by!(title: "Wedding Essential Set") do |deal|
  deal.description = "Necklace, Earrings and Maang Tikka"
  deal.original_price = 3599
  deal.discounted_price = 2499
  deal.discount_percentage = 30
  deal.icon_emoji = "💍"
  deal.position = 1
  deal.active = true
end

BundleDeal.find_or_create_by!(title: "Festive Combo") do |deal|
  deal.description = "Bangles and Earrings Pair"
  deal.original_price = 1749
  deal.discounted_price = 1299
  deal.discount_percentage = 25
  deal.icon_emoji = "📿"
  deal.position = 2
  deal.active = true
end

BundleDeal.find_or_create_by!(title: "Complete Jewelry Set") do |deal|
  deal.description = "Full Bridal Collection 8 pieces"
  deal.original_price = 8499
  deal.discounted_price = 4999
  deal.discount_percentage = 40
  deal.icon_emoji = "💎"
  deal.position = 3
  deal.active = true
end

puts "Created #{BundleDeal.count} bundle deals"
