# frozen_string_literal: true

require "date"
require "time"

module Foxtail
  # Built-in formatting functions
  # Corresponds to fluent-bundle/src/builtins.ts
  module Functions
    # Default functions available to all bundles
    # Using lazy initialization to avoid circular loading issues
    def self.defaults
      @defaults ||= {
        "NUMBER" => CLDR::Formatter::Number.new.freeze,
        "DATETIME" => CLDR::Formatter::DateTime.new.freeze
      }.freeze
    end

    # Access individual function by name
    # @param name [String] Function name ("NUMBER" or "DATETIME")
    # @return [Object] The function instance
    def self.[](name)
      defaults[name]
    end
  end
end
