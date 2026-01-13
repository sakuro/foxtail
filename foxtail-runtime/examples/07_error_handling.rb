# frozen_string_literal: true

# Example 07: Error Handling
#
# This example demonstrates:
# - Missing variable handling
# - Missing message handling
# - Missing reference handling

require "foxtail"

bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"), use_isolating: false)

resource = Foxtail::Resource.from_string(<<~FTL)
  # Message with variable
  welcome = Welcome, { $name }! You have { $count } messages.
  # Message referencing another message
  greet-user = { greeting }, { $name }!
  # Valid greeting
  greeting = Hello
FTL
bundle.add_resource(resource)

puts "--- Missing Variables ---"
# When a variable is missing, it renders as {$variable}
puts bundle.format("welcome")
# => Welcome, {$name}! You have {$count} messages.

# Partial variables - only some provided
puts bundle.format("welcome", name: "Alice")
# => Welcome, Alice! You have {$count} messages.

# All variables provided
puts bundle.format("welcome", name: "Alice", count: 5)
# => Welcome, Alice! You have 5 messages.

puts "\n--- Message References ---"
# Message referencing another message
puts bundle.format("greet-user", name: "Bob")
# => Hello, Bob!

puts "\n--- Missing Messages ---"
# When a message is not found, format returns the message ID
puts bundle.format("nonexistent")
# => nonexistent

puts bundle.format("also-missing")
# => also-missing

puts "\n--- Checking Message Existence ---"
# Use message? to check if a message exists before formatting
%w[welcome greeting nonexistent].each do |id|
  exists = bundle.message?(id)
  puts "#{id}: #{exists ? "exists" : "not found"}"
end
