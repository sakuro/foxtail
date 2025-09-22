# frozen_string_literal: true

require "date"
require "execjs"
require "locale"
require "time"

module Foxtail
  # Built-in formatting functions for FTL
  # Provides direct access to JavaScript and Foxtail::Intl formatters
  module Function
    # Current backend type
    # @return [Symbol] Current backend (:javascript or :foxtail_intl)
    def self.backend
      @backend ||= detect_best_backend
    end

    # Set backend type
    # @param backend_type [Symbol] Backend type (:auto, :javascript, or :foxtail_intl)
    def self.backend=(backend_type)
      if backend_type == :auto
        @backend = detect_best_backend
      elsif %i[javascript foxtail_intl].include?(backend_type)
        @backend = backend_type
      else
        raise ArgumentError, "Backend must be :auto, :javascript, or :foxtail_intl"
      end
    end

    # Default functions available to all bundles
    # Returns Proc functions that instantiate formatters and call them
    def self.defaults
      case backend
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
    # @return [Symbol] Best available backend type
    private_class_method def self.detect_best_backend
      # Try JavaScript first (better standards compliance), fallback to Foxtail::Intl (faster)
      js_formatter = JavaScript::NumberFormat.new(locale: Locale::Tag.parse("en"))
      js_formatter.available? ? :javascript : :foxtail_intl
    rescue
      :foxtail_intl
    end
  end
end
