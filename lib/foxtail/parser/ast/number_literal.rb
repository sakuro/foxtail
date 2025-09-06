# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      # Represents numeric literals (integers and floats)
      class NumberLiteral < BaseLiteral
        # Parse the number literal value and return as a Hash
        # @return [Hash] Hash containing the parsed numeric value
        def parse
          value_str = @value

          if value_str.include?(".")
            {value: Float(value_str)}
          else
            {value: Integer(value_str, 10)}
          end
        end
      end
    end
  end
end
