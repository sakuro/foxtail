# frozen_string_literal: true

require "date"
require "locale"
require "time"

module Foxtail
  # Built-in formatting functions for FTL
  # Uses ICU4X for number and datetime formatting
  module Function
    # Current backend type
    # @return [Symbol] Current backend (:icu4x)
    def self.backend
      @backend ||= detect_best_backend
    end

    # Set backend type
    # @param backend_type [Symbol] Backend type (:auto or :icu4x)
    def self.backend=(backend_type)
      if backend_type == :auto
        @backend = detect_best_backend
      elsif backend_type == :icu4x
        @backend = backend_type
      else
        raise ArgumentError, "Backend must be :auto or :icu4x"
      end
    end

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
    def self.[](name)
      defaults[name]
    end

    # Detect best available backend
    # @return [Symbol] Best available backend type (icu4x is preferred)
    private_class_method def self.detect_best_backend
      :icu4x
    end
  end
end
