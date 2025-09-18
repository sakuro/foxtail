# frozen_string_literal: true

require "date"
require "time"

module Foxtail
  # Built-in formatting functions
  # Corresponds to fluent-bundle/src/builtins.ts
  module Functions
    # Default functions available to all bundles
    # Each function is a Proc that accepts (value, locale:, **options) and returns formatted result
    def self.defaults
      @defaults ||= {
        "NUMBER" => ->(value, locale:, **options) {
          CLDR::Formatter::Number.new(locale:, **options).call(value)
        },
        "DATETIME" => ->(value, locale:, **options) {
          CLDR::Formatter::DateTime.new(locale:, **options).call(value)
        }
      }.freeze
    end

    # Access individual function by name
    # @param name [String] Function name ("NUMBER" or "DATETIME")
    # @return [Proc] The function Proc that accepts (value, locale:, **options)
    def self.[](name)
      defaults[name]
    end
  end
end
