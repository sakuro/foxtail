# frozen_string_literal: true

# E-commerce Example
#
# This example demonstrates:
# - Currency formatting with NUMBER function
# - Percent formatting for discounts
# - Plurals for stock counts and cart items
# - Loading FTL files from disk

require "foxtail"
require "icu4x"
require "pathname"

# Directory containing locale files
locales_dir = Pathname.new(__dir__).join("locales")

# Load bundles for available locales
en_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"), use_isolating: false)
en_bundle.add_resource(Foxtail::Resource.from_file(locales_dir.join("en.ftl")))

ja_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"), use_isolating: false)
ja_bundle.add_resource(Foxtail::Resource.from_file(locales_dir.join("ja.ftl")))

# Sample product data
product = {
  name: "Wireless Headphones",
  price_usd: 149.99,
  price_jpy: 22_000,
  discount: 0.2,
  stock: 3,
  rating: 4.7,
  reviews: 128
}

puts "=== E-commerce Localization Demo ==="
puts

# English (US) display
puts "--- English (US) ---"
puts en_bundle.format("product-name", name: product[:name])
puts en_bundle.format("product-price", price: product[:price_usd])
puts en_bundle.format("product-discount", percent: product[:discount])
puts en_bundle.format("stock-status", count: product[:stock])
puts en_bundle.format("reviews-count", count: product[:reviews])
puts en_bundle.format("reviews-rating", rating: product[:rating])
puts

# Japanese display
puts "--- Japanese ---"
puts ja_bundle.format("product-name", name: product[:name])
puts ja_bundle.format("product-price", price: product[:price_jpy])
puts ja_bundle.format("product-discount", percent: product[:discount])
puts ja_bundle.format("stock-status", count: product[:stock])
puts ja_bundle.format("reviews-count", count: product[:reviews])
puts ja_bundle.format("reviews-rating", rating: product[:rating])
puts

# Cart examples
puts "=== Shopping Cart ==="
puts

cart_items = 5
cart_total_usd = 749.95
cart_total_jpy = 110_000

puts "English:"
puts "  #{en_bundle.format("cart-items", count: cart_items)}"
puts "  #{en_bundle.format("cart-total", total: cart_total_usd)}"
puts "  #{en_bundle.format("shipping-free", threshold: 100)}"
puts

puts "Japanese:"
puts "  #{ja_bundle.format("cart-items", count: cart_items)}"
puts "  #{ja_bundle.format("cart-total", total: cart_total_jpy)}"
puts "  #{ja_bundle.format("shipping-free", threshold: 10_000)}"
puts

# Empty cart
puts "=== Empty Cart ==="
puts "English: #{en_bundle.format("cart-items", count: 0)}"
puts "Japanese: #{ja_bundle.format("cart-items", count: 0)}"
puts

# Sale banner
puts "=== Sale Banner ==="
puts "English: #{en_bundle.format("sale-banner", maxDiscount: 0.5)}"
puts "Japanese: #{ja_bundle.format("sale-banner", maxDiscount: 0.5)}"
