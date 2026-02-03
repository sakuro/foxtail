# frozen_string_literal: true

module Foxtail
  module Function
    # Base class for deferred-formatting values
    # Wraps a value with formatting options, deferring locale-specific formatting until display time
    class Value
      # @return [Object] The wrapped raw value
      attr_reader :value

      # @return [Hash] Formatting options
      attr_reader :options

      # @param value [Object] The value to wrap
      # @param options [Hash] Formatting options (camelCase keys from FTL)
      def initialize(value, **options)
        @value = value
        @options = options
      end

      # Format the value for display
      # Subclasses may override for locale-specific formatting
      # @param bundle [Foxtail::Bundle] The bundle providing locale and context (unused in base implementation)
      # @return [String] The formatted value
      def format(**) = @value.to_s
    end
  end
end
