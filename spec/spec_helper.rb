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

  # Configure ExecJS runtime for JavaScript backend tests
  config.before(:suite) do
    # Check if Node.js is available and set as default runtime
    if system("node --version > /dev/null 2>&1")
      require "execjs"
      @original_runtime = ExecJS.runtime
      ExecJS.runtime = ExecJS::Runtimes::Node
    end
  end

  config.after(:suite) do
    # Restore original runtime if it was changed
    ExecJS.runtime = @original_runtime if defined?(@original_runtime)
  end
end
