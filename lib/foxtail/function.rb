# frozen_string_literal: true

require "date"
require "execjs"
require "locale"
require "time"

module Foxtail
  # Built-in formatting functions for FTL
  # Provides direct access to ICU4X, JavaScript, and Foxtail::Intl formatters
  module Function
    # Current backend type
    # @return [Symbol] Current backend (:icu4x, :javascript, or :foxtail_intl)
    def self.backend
      @backend ||= detect_best_backend
    end

    # Set backend type
    # @param backend_type [Symbol] Backend type (:auto, :icu4x, :javascript, or :foxtail_intl)
    def self.backend=(backend_type)
      if backend_type == :auto
        @backend = detect_best_backend
      elsif %i[icu4x javascript foxtail_intl].include?(backend_type)
        @backend = backend_type
      else
        raise ArgumentError, "Backend must be :auto, :icu4x, :javascript, or :foxtail_intl"
      end
    end

    # Default functions available to all bundles
    # Returns Proc functions that instantiate formatters and call them
    def self.defaults
      case backend
      when :icu4x
        {
          "NUMBER" => ->(value, locale:, **options) {
            Icu4xBackend::NumberFormat.new(locale:, **options).call(value)
          },
          "DATETIME" => ->(value, locale:, **options) {
            Icu4xBackend::DateTimeFormat.new(locale:, **options).call(value)
          }
        }
      when :javascript
        {
          "NUMBER" => ->(value, locale:, **options) {
            JavaScript::NumberFormat.new(locale:, **options).call(value)
          },
          "DATETIME" => ->(value, locale:, **options) {
            JavaScript::DateTimeFormat.new(locale:, **options).call(value)
          }
        }
      when :foxtail_intl
        {
          "NUMBER" => ->(value, locale:, **options) {
            Foxtail::Intl::NumberFormat.new(locale:, **options).call(value)
          },
          "DATETIME" => ->(value, locale:, **options) {
            Foxtail::Intl::DateTimeFormat.new(locale:, **options).call(value)
          }
        }
      end
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
