# frozen_string_literal: true

require "icu4x"

# Shared context for locale helper method
RSpec.shared_context "with locale" do
  def locale(locale_string) = ICU4X::Locale.parse(locale_string)
end

# Include locale helpers in all specs
RSpec.configure do |config|
  config.include_context "with locale"
end
