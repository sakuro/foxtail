# frozen_string_literal: true

module Foxtail
  module Function
    Value = Data.define(:value, :options)

    # Base class for deferred-formatting values
    # Wraps a value with formatting options, deferring locale-specific formatting until display time
    #
    # @!attribute [r] value
    #   @return [Object] The wrapped raw value
    # @!attribute [r] options
    #   @return [Hash] Formatting options
    class Value
      # Format the value for display
      # Subclasses may override for locale-specific formatting
      # @param bundle [Foxtail::Bundle] The bundle providing locale and context (unused in base implementation)
      # @return [String] The formatted value
      def format(**) = value.to_s

      # String representation for interpolation
      # @return [String] The string representation of the wrapped value
      def to_s = value.to_s
    end
  end
end
