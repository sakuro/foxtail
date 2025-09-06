# frozen_string_literal: true

require "date"
require "time"
require_relative "cldr"
require_relative "cldr/number_formats"
require_relative "functions/date_time_formatter"
require_relative "functions/number_formatter"

module Foxtail
  # Built-in formatting functions
  # Corresponds to fluent-bundle/src/builtins.ts
  module Functions
    # Default functions available to all bundles
    DEFAULTS = {
      "NUMBER" => NumberFormatter.new.freeze,
      "DATETIME" => DateTimeFormatter.new.freeze
    }.freeze
    private_constant :DEFAULTS

    # Access individual function by name
    # @param name [String] Function name ("NUMBER" or "DATETIME")
    # @return [Object] The function instance
    def self.[](name)
      DEFAULTS[name]
    end

    # Create a functions hash for Bundle initialization
    # Returns a copy of DEFAULTS for modification safety
    def self.defaults
      DEFAULTS.dup
    end
  end
end
