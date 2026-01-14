# frozen_string_literal: true

# Example 01: Basic Messages and Variables
#
# This example demonstrates:
# - Creating a Bundle with a locale
# - Parsing FTL resources from strings
# - Formatting messages with variables

require "foxtail-runtime"

# Create a bundle for English (US) locale
bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"), use_isolating: false)

# Parse FTL content and add to bundle
resource = Foxtail::Resource.from_string(<<~FTL)
  # Simple message
  hello-world = Hello, World!
  # Message with variable
  greeting = Hello, { $name }!
  # Message with multiple variables
  welcome = Welcome to { $app }, { $user }!
FTL

bundle.add_resource(resource)

# Format simple message
puts bundle.format("hello-world")
# => Hello, World!

# Format message with variable
puts bundle.format("greeting", name: "Alice")
# => Hello, Alice!

# Format message with multiple variables
puts bundle.format("welcome", app: "Foxtail", user: "Bob")
# => Welcome to Foxtail, Bob!

# Missing variable renders as placeholder
puts bundle.format("greeting")
# => Hello, {$name}!
