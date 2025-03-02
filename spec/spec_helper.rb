# frozen_string_literal: true

require "foxtail"
require "json"

# Load all support files
Dir["spec/support/**/*.rb"].each {|f| load f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Automatically include shared contexts and helpers when ftl_fixture tag is specified
  config.include_context "with ftl fixture", ftl_fixture: /.+/
  config.include FtlHelpers, ftl_fixture: /.+/
end
