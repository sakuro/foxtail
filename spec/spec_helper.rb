# frozen_string_literal: true

require "simplecov"

require "foxtail"
require_relative "support/cldr_fixture_helper"
require_relative "support/locale_context"
require_relative "support/logging_context"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include CLDR fixture helper
  config.include CLDRFixtureHelper
end
