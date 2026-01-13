# frozen_string_literal: true

# Example 02: Selectors (Plurals, Gender, Numeric Matching)
#
# This example demonstrates:
# - Plural forms with numeric values
# - String-based selectors (gender, etc.)
# - Exact numeric matching with fallback

require "foxtail"

bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"), use_isolating: false)

resource = Foxtail::Resource.from_string(<<~FTL)
  # Plural selector - matches plural categories (zero, one, two, few, many, other)
  emails =
      You have { $count ->
          [0] no emails
          [one] one email
         *[other] { $count } emails
      }.
  # String selector - matches exact string values
  greeting =
      { $gender ->
          [male] Hello, Mr. { $name }!
          [female] Hello, Ms. { $name }!
         *[other] Hello, { $name }!
      }
  # Numeric selector with exact matches
  position =
      You are in { $place ->
          [1] first
          [2] second
          [3] third
         *[other] { $place }th
      } place.
FTL

bundle.add_resource(resource)

# Plural selector
puts "--- Plural Selector ---"
puts bundle.format("emails", count: 0)   # => You have no emails.
puts bundle.format("emails", count: 1)   # => You have one email.
puts bundle.format("emails", count: 5)   # => You have 5 emails.

# Gender selector
puts "\n--- Gender Selector ---"
puts bundle.format("greeting", gender: "male", name: "John")
# => Hello, Mr. John!
puts bundle.format("greeting", gender: "female", name: "Jane")
# => Hello, Ms. Jane!
puts bundle.format("greeting", gender: "other", name: "Alex")
# => Hello, Alex!

# Numeric selector
puts "\n--- Numeric Selector ---"
puts bundle.format("position", place: 1)   # => You are in first place.
puts bundle.format("position", place: 2)   # => You are in second place.
puts bundle.format("position", place: 10)  # => You are in 10th place.
