# This file delegates to modular rake tasks in lib/tasks/seed.rake
#
# Usage:
#   rails db:seed              — runs all 3 sections
#   rails seed:homepage        — Section 1: admin, categories, banners, homepage collections, coupons
#   rails seed:products        — Section 2: products, variants, inventory
#   rails seed:orders          — Section 3: customers, addresses, reviews, demo orders
#   rails seed:all             — same as db:seed

Rake::Task["seed:all"].invoke
