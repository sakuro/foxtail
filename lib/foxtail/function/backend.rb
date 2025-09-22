# frozen_string_literal: true

module Foxtail
  module Function
    # Backend implementations for FTL functions
    module Backend
      # Abstract base class for all backends
      class Base
        # Execute FTL function
        # @param function_name [String] Function name ("NUMBER" or "DATETIME")
        # @param value [Object] Value to format
        # @param locale [Locale::Tag::Simple] Locale for formatting
        # @param options [Hash] Formatting options
        # @return [String] Formatted result
        # @raise [ArgumentError] For unknown function names or invalid values
        def call(function_name, value, locale:, **options)
          raise NotImplementedError, "#{self.class} must implement #call"
        end

        # Check if backend is available
        # @return [Boolean] True if backend can be used
        def available?
          raise NotImplementedError, "#{self.class} must implement #available?"
        end

        # Backend name for identification
        # @return [String] Human-readable backend name
        def name
          raise NotImplementedError, "#{self.class} must implement #name"
        end

        # List of supported function names
        # @return [Array<String>] Supported function names
        def supported_functions
          %w[NUMBER DATETIME]
        end

        # Check if function is supported
        # @param function_name [String] Function name to check
        # @return [Boolean] True if function is supported
        def supports?(function_name)
          supported_functions.include?(function_name.to_s.upcase)
        end
      end

      # Backend selection and configuration
      class << self
        private def detect_best_backend
          available_backends.first || raise(
            RuntimeError,
            "No function backends available"
          )
        end
      end

      # Get default backend instance
      # @return [Base] Default backend instance
      def self.default
        @default ||= detect_best_backend
      end

      # Set default backend
      # @param backend [Base] Backend instance to use as default
      def self.default=(backend)
        unless backend.is_a?(Base)
          raise ArgumentError, "Backend must be a subclass of Foxtail::Function::Backend::Base"
        end

        @default = backend
      end

      # Get list of available backends
      # Ordered by preference: JavaScript (faster) first, FoxtailIntl (always available) as fallback
      # @return [Array<Base>] Available backend instances
      def self.available_backends
        [
          JavaScript.new,
          FoxtailIntl.new
        ].select(&:available?)
      end
    end
  end
end
