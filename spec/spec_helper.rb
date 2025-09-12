# frozen_string_literal: true

require "simplecov"

require "foxtail"
require_relative "support/locale_context"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Suppress log output during tests
  config.before do
    allow(Foxtail::CLDR::Inheritance.instance).to receive(:log)
    allow_any_instance_of(Foxtail::CLDR::Resolver).to receive(:log)
  end
end
