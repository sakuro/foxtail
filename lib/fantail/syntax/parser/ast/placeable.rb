# frozen_string_literal: true

module Fantail
  module Syntax
    class Parser
      module AST
        # Represents expressions within braces {} in a pattern that are evaluated at runtime
        class Placeable < SyntaxNode
          attr_accessor :expression

          def initialize(expression)
            super()
            @expression = expression
          end
        end
      end
    end
  end
end
