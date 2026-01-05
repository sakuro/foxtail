# frozen_string_literal: true

# Example 06: Custom Functions
#
# This example demonstrates:
# - Defining custom formatting functions
# - Merging with default functions
# - Using custom functions in FTL messages

require "foxtail"

# Define custom functions
# Signature: (value, locale:, **options)
# - value: The first positional argument from FTL
# - locale: The bundle's locale (ICU4X::Locale)
# - options: Named arguments from FTL as keyword arguments
custom_functions = {
  # UPPER function - converts text to uppercase
  "UPPER" => ->(value, **_opts) { value.to_s.upcase },

  # LOWER function - converts text to lowercase
  "LOWER" => ->(value, **_opts) { value.to_s.downcase },

  # REVERSE function - reverses text
  "REVERSE" => ->(value, **_opts) { value.to_s.reverse }
}

# Merge with default functions (NUMBER, DATETIME) to keep them available
all_functions = Foxtail::Function.defaults.merge(custom_functions)

# Create bundle with merged functions
bundle = Foxtail::Bundle.new(
  ICU4X::Locale.parse("en-US"),
  functions: all_functions
)

resource = Foxtail::Resource.from_string(<<~FTL)
  # Using custom UPPER function
  shout = { UPPER($text) }
  # Using custom LOWER function
  whisper = { LOWER($text) }
  # Using custom REVERSE function
  backwards = { REVERSE($text) }
  # Combining with regular text
  greeting = Hello, { UPPER($name) }! Welcome aboard.
  # Still have access to default NUMBER function
  price = Total: { NUMBER($amount, style: "currency", currency: "USD") }
FTL

bundle.add_resource(resource)

puts "--- Custom Functions ---"

puts bundle.format("shout", text: "Hello World")
# => HELLO WORLD

puts bundle.format("whisper", text: "QUIET PLEASE")
# => quiet please

puts bundle.format("backwards", text: "Foxtail")
# => liatxoF

puts bundle.format("greeting", name: "alice")
# => Hello, ALICE! Welcome aboard.

puts "\n--- Default Functions Still Work ---"
puts bundle.format("price", amount: 99.99)
# => Total: $99.99
