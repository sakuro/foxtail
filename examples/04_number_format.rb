# frozen_string_literal: true

# Example 04: Number Formatting
#
# This example demonstrates:
# - NUMBER function for locale-aware formatting
# - Currency formatting
# - Percentage formatting
# - Decimal digit control

require "foxtail"

# English (US)
en_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"), use_isolating: false)
en_resource = Foxtail::Resource.from_string(<<~FTL)
  # Basic number formatting
  count = Total: { NUMBER($value) }
  # Currency formatting
  price = Price: { NUMBER($amount, style: "currency", currency: "USD") }
  # Percentage
  discount = Save { NUMBER($rate, style: "percent") }!
  # Controlling decimal places
  precise = Value: { NUMBER($num, minimumFractionDigits: 2, maximumFractionDigits: 2) }
  # Large numbers with grouping
  population = Population: { NUMBER($count) }
FTL
en_bundle.add_resource(en_resource)

# Japanese
ja_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"), use_isolating: false)
ja_resource = Foxtail::Resource.from_string(<<~FTL)
  # Currency in Yen
  price = 価格：{ NUMBER($amount, style: "currency", currency: "JPY") }
  # Percentage
  discount = { NUMBER($rate, style: "percent") }オフ！
  # Large numbers
  population = 人口：{ NUMBER($count) }人
FTL
ja_bundle.add_resource(ja_resource)

puts "=== English (US) ==="

puts en_bundle.format("count", value: 42)
# => Total: 42

puts en_bundle.format("price", amount: 1234.50)
# => Price: $1,234.50

puts en_bundle.format("discount", rate: 0.25)
# => Save 25%!

puts en_bundle.format("precise", num: 3.14159)
# => Value: 3.14

puts en_bundle.format("population", count: 1_000_000)
# => Population: 1,000,000

puts "\n=== Japanese ==="

puts ja_bundle.format("price", amount: 1234)
# => 価格：￥1,234

puts ja_bundle.format("discount", rate: 0.25)
# => 25%オフ！

puts ja_bundle.format("population", count: 1_000_000)
# => 人口：1,000,000人
