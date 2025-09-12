# frozen_string_literal: true

# Shared context for suppressing log output during tests
RSpec.shared_context "with logging suppressed" do
  let(:suppressed_logger) { instance_double(Dry::Logger::Dispatcher, info: nil, warn: nil, debug: nil, error: nil) }

  before do
    allow(Foxtail::CLDR).to receive(:logger).and_return(suppressed_logger)
  end
end

# Suppress logging in all specs
RSpec.configure do |config|
  config.include_context "with logging suppressed"
end
