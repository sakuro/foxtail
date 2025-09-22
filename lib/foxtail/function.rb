# frozen_string_literal: true

require "date"
require "time"

module Foxtail
  # Built-in formatting functions for FTL
  # Uses pluggable backends for actual formatting implementation
  module Function
    # Default backend instance
    # @return [Backend::Base] Current backend instance
    def self.backend
      @backend ||= Backend.default
    end

    # Set backend instance
    # @param new_backend [Backend::Base] Backend to use for formatting
    def self.backend=(new_backend)
      unless new_backend.is_a?(Backend::Base)
        raise ArgumentError, "Backend must be a subclass of Foxtail::Function::Backend::Base"
      end

      @backend = new_backend
    end

    # Default functions available to all bundles
    # Each function is a Proc that delegates to the current backend
    def self.defaults
      @defaults ||= {
        "NUMBER" => ->(value, locale:, **options) {
          backend.call("NUMBER", value, locale:, **options)
        },
        "DATETIME" => ->(value, locale:, **options) {
          backend.call("DATETIME", value, locale:, **options)
        }
      }.freeze
    end

    # Access individual function by name
    # @param name [String] Function name ("NUMBER" or "DATETIME")
    # @return [Proc] The function Proc that accepts (value, locale:, **options)
    def self.[](name)
      defaults[name]
    end

    # Configure backend with options
    # @param backend_name [Symbol] Backend type (:auto, :javascript, :foxtail_intl)
    # @param options [Hash] Backend-specific configuration options
    # @example Use JavaScript backend explicitly
    #   Foxtail::Function.configure(backend_name: :javascript)
    # @example Use FoxtailIntl backend
    #   Foxtail::Function.configure(backend_name: :foxtail_intl)
    # @example Auto-detect best available backend (default)
    #   Foxtail::Function.configure(backend_name: :auto)
    def self.configure(backend_name: :auto, **_options)
      self.backend = backend_name == :auto ? Backend.default : Backend.create(backend_name)
    end

    # Get information about current backend
    # @return [Hash] Backend information
    def self.backend_info
      {
        name: backend.name,
        available: backend.available?,
        supported_functions: backend.supported_functions
      }
    end
  end
end
