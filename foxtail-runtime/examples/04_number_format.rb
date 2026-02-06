# frozen_string_literal: true

# Example 04: Number Formatting
#
# This example demonstrates:
# - Implicit NUMBER formatting for numeric variables
# - Explicit NUMBER function for currency, percent, and precision options
# - Locale-aware formatting

require "foxtail-runtime"
require "icu4x-data-recommended"

# English (US)
en_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"), use_isolating: false)
en_resource = Foxtail::Resource.from_string(<<~FTL)
  # Implicit NUMBER formatting (automatically applied to numeric variables)
  count = Total: { $value }
  # Currency formatting (requires explicit NUMBER with options)
  price = Price: { NUMBER($amount, style: "currency", currency: "USD") }
  # Percentage (requires explicit NUMBER with options)
  discount = Save { NUMBER($rate, style: "percent") }!
  # Controlling decimal places (requires explicit NUMBER with options)
  precise = Value: { NUMBER($num, minimumFractionDigits: 2, maximumFractionDigits: 2) }
  # Large numbers with implicit grouping
  population = Population: { $count }
FTL
en_bundle.add_resource(en_resource)

# Japanese
ja_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"), use_isolating: false)
ja_resource = Foxtail::Resource.from_string(<<~FTL)
  # Currency in Yen (requires explicit NUMBER with options)
  price = 価格：{ NUMBER($amount, style: "currency", currency: "JPY") }
  # Percentage (requires explicit NUMBER with options)
  discount = { NUMBER($rate, style: "percent") }オフ！
  # Large numbers with implicit grouping
  population = 人口：{ $count }人
FTL
ja_bundle.add_resource(ja_resource)

puts "=== English (US) ==="

puts en_bundle.format("count", value: 1234)
# => Total: 1,234

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
