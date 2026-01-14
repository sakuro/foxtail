# frozen_string_literal: true

# Example 03: Attributes and Terms
#
# This example demonstrates:
# - Term definitions (-term syntax)
# - Term references in messages
# - Message attributes (.attribute syntax)
# - Referencing attributes within FTL

require "foxtail-runtime"

bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"), use_isolating: false)

resource = Foxtail::Resource.from_string(<<~FTL)
  # Term - reusable value (prefixed with -)
  -brand = Foxtail
  # Message referencing a term
  about = About { -brand }
  # Another term
  -company = Acme Corp
  # Multiple terms in one message
  copyright = Copyright { -company }. Powered by { -brand }.
  # Message with attributes (for localized HTML attributes, etc.)
  login-button = Log In
      .aria-label = Click to log in
      .title = Login to your account
  # Referencing message attribute from another message
  login-help = { login-button.aria-label } to access your account.
FTL

bundle.add_resource(resource)

# Term reference
puts "--- Term Reference ---"
puts bundle.format("about")
# => About Foxtail

# Multiple terms
puts "\n--- Multiple Terms ---"
puts bundle.format("copyright")
# => Copyright Acme Corp. Powered by Foxtail.

# Message value
puts "\n--- Message with Attributes ---"
puts bundle.format("login-button")
# => Log In

# Message attribute referenced from another message
puts "\n--- Attribute Reference ---"
puts bundle.format("login-help")
# => Click to log in to access your account.
