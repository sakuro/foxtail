# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      # Parse error with detailed error codes and messages
      class ParseError < Error
        # @return [String] Error code (e.g., "E0001", "E0002")
        attr_reader :code
        # @return [Array] Additional arguments for error message formatting
        attr_reader :args

        # @param code [String] Error code
        # @param args [Array] Additional arguments for error message formatting
        def initialize(code, *args)
          @code = code
          @args = args
          super(error_message(code, args))
        end

        private def error_message(code, args)
          case code
          when "E0001"
            "Generic error"
          when "E0002"
            "Expected an entry start"
          when "E0003"
            token = args[0]
            "Expected token: \"#{token}\""
          when "E0004"
            range = args[0]
            "Expected a character from range: \"#{range}\""
          when "E0005"
            id = args[0]
            "Expected message \"#{id}\" to have a value or attributes"
          when "E0006"
            id = args[0]
            "Expected term \"-#{id}\" to have a value"
          when "E0007"
            "Expected a keyword"
          when "E0008"
            "The callee has to be an upper-case identifier or a term"
          when "E0009"
            "The argument name has to be a simple identifier"
          when "E0010"
            "Expected one of the variants to be marked as default (*)"
          when "E0011"
            "Expected at least one variant after \"->\""
          when "E0012"
            "Expected value"
          when "E0013"
            "Expected a variant key"
          when "E0014"
            "Expected literal"
          when "E0015"
            "Only one variant can be marked as default (*)"
          when "E0016"
            "Message references cannot be used as selectors"
          when "E0017"
            "Terms cannot be used as selectors"
          when "E0018"
            "Attributes of messages cannot be used as selectors"
          when "E0019"
            "Attributes of terms cannot be used as placeables"
          when "E0020"
            "Unterminated string expression"
          when "E0021"
            "Positional arguments must not follow named arguments"
          when "E0022"
            "Named arguments must be unique"
          when "E0023"
            "Expected an option list"
          when "E0024"
            "Expected a keyword argument"
          when "E0025"
            arg = args[0]
            "Unknown escape sequence: \\#{arg}."
          when "E0026"
            sequence = args[0]
            "Invalid Unicode escape sequence: #{sequence}."
          when "E0027"
            "Unbalanced closing brace in TextElement."
          when "E0028"
            "Expected an inline expression"
          when "E0029"
            "Nested placeables are not allowed"
          else
            "Unknown error: #{code}"
          end
        end
      end
    end
  end
end
