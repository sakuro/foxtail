# frozen_string_literal: true

module Fantail
  module Syntax
    class Parser
      module AST
        # Base class for literal values (strings and numbers) with parsing capability
        class BaseLiteral < SyntaxNode
          attr_accessor :value

          def initialize(value)
            super()
            # The "value" field contains the exact contents of the literal,
            # character-for-character.
            @value = value
          end

          # Abstract method - subclasses must implement
          def parse = raise NotImplementedError, "Subclasses must implement parse method"
        end
      end
    end
  end
end
