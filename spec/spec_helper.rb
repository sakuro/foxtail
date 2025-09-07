# frozen_string_literal: true

require "foxtail"
require "locale"

# Shared context for locale helper method
RSpec.shared_context "with locale" do
  def locale(locale_string) = Locale::Tag.parse(locale_string)
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Include locale helpers in all specs
  config.include_context "with locale"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
