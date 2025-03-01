# frozen_string_literal: true

module Foxtail
  module Errors
    # Base error class for all Foxtail errors
    class Error < StandardError
    end

    # Error raised when parsing fails
    class ParseError < Error
      attr_reader :code
      attr_reader :args

      def initialize(code, *args)
        @code = code
        @args = args
        super(message)
      end

      def message
        case @code
        when "E0001"
          "Generic error"
        when "E0002"
          "Expected an entry start"
        when "E0003"
          "Expected token: #{@args[0]}"
        when "E0004"
          "Expected a character from range: #{@args[0]}"
        when "E0005"
          "Expected message #{@args[0]} to have a value or attributes"
        when "E0006"
          "Expected term #{@args[0]} to have a value"
        when "E0007"
          "Keyword cannot be used as an identifier: #{@args[0]}"
        when "E0008"
          "The callee has to be a function: #{@args[0]}"
        when "E0009"
          "The argument must be a message reference: #{@args[0]}"
        when "E0010"
          "Expected one of the variants to be marked as default (*)"
        when "E0011"
          "Expected at least one variant after the selector"
        when "E0012"
          "Expected value"
        when "E0013"
          "Expected variant key"
        when "E0014"
          "Expected literal"
        when "E0015"
          "Only one variant can be marked as default (*)"
        when "E0016"
          "Message references cannot be used as selectors"
        when "E0017"
          "Terms cannot be used as selectors"
        when "E0018"
          "Attributes of message references cannot be used as selectors"
        when "E0019"
          "Attributes of terms cannot be used as placeables"
        when "E0020"
          "Unterminated string literal"
        when "E0021"
          "Positional arguments must not follow named arguments"
        when "E0022"
          "Named arguments must be unique"
        when "E0024"
          "Cannot access variants of a message: #{@args[0]}"
        when "E0025"
          "Unknown escape sequence: \\#{@args[0]}"
        when "E0026"
          "Invalid Unicode escape sequence: #{@args[0]}"
        when "E0027"
          "Unbalanced closing brace in TextElement"
        when "E0028"
          "Expected an expression"
        when "E0029"
          "Placeable expressions cannot be used as selectors"
        else
          "Unknown error: #{@code}"
        end
      end
    end
  end
end
