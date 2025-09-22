# frozen_string_literal: true

require "simplecov"

require "foxtail"
require_relative "support/extractor_context"
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

  # Automatically include extractor directory management for extractor specs
  config.include_context "when using extractor directory management", type: :extractor

  # Skip JavaScript tests when no runtime is available
  config.before(:each, :requires_javascript) do
    require "execjs"
    skip "JavaScript runtime not available" unless ExecJS.runtime
  end
end
