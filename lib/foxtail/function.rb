# frozen_string_literal: true

require "date"
require "locale"
require "time"

module Foxtail
  # Built-in formatting functions for FTL
  # Uses ICU4X for number and datetime formatting
  module Function
    # Default functions available to all bundles
    # Returns Proc functions that instantiate formatters and call them
    def self.defaults
      {
        "NUMBER" => ->(value, locale:, **options) {
          Icu4xBackend::NumberFormat.new(locale:, **options).call(value)
        },
        "DATETIME" => ->(value, locale:, **options) {
          Icu4xBackend::DateTimeFormat.new(locale:, **options).call(value)
        }
      }
    end

    # Access individual function by name
    # @param name [String] Function name ("NUMBER" or "DATETIME")
    # @return [Proc] The function Proc that accepts (value, locale:, **options)
    def self.[](name) = defaults[name]
  end
end
