# frozen_string_literal: true

module Foxtail
  # Built-in formatting functions for FTL
  # Uses ICU4X for number and datetime formatting
  module Function
    # Default functions available to all bundles
    # @return [Hash{String => #call}] Function name to callable object mapping
    def self.defaults
      {
        "NUMBER" => ->(value, **options) { Number.new(value, **options) },
        "DATETIME" => ->(value, **options) { DateTime.new(value, **options) }
      }
    end
  end
end
