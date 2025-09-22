# frozen_string_literal: true

require "date"
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
    # @param backend_type [Symbol] Backend type (:javascript or :foxtail_intl)
    def self.backend=(backend_type)
      unless %i[javascript foxtail_intl].include?(backend_type)
        raise ArgumentError, "Backend must be :javascript or :foxtail_intl"
      end

      @backend = backend_type
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

    # Configure backend with options
    # @param backend_name [Symbol] Backend type (:auto, :javascript, :foxtail_intl)
    # @param options [Hash] Backend-specific configuration options (unused in new design)
    # @example Use JavaScript backend explicitly
    #   Foxtail::Function.configure(backend_name: :javascript)
    # @example Use FoxtailIntl backend
    #   Foxtail::Function.configure(backend_name: :foxtail_intl)
    # @example Auto-detect best available backend (default)
    #   Foxtail::Function.configure(backend_name: :auto)
    def self.configure(backend_name: :auto, **_options)
      self.backend = backend_name == :auto ? detect_best_backend : backend_name
    end

    # Get information about current backend
    # @return [Hash] Backend information
    def self.backend_info
      case backend
      when :javascript
        js_formatter = JavaScript::NumberFormat.new(locale: Locale::Tag.parse("en"))
        {
          name: "JavaScript (#{js_formatter.available? ? "available" : "unavailable"})",
          available: js_formatter.available?,
          supported_functions: %w[NUMBER DATETIME]
        }
      when :foxtail_intl
        {
          name: "Foxtail-Intl (native Ruby CLDR)",
          available: true,
          supported_functions: %w[NUMBER DATETIME]
        }
      end
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
