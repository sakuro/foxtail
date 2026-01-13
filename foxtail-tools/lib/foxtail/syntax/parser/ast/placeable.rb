# frozen_string_literal: true

module Foxtail
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

          def children = [expression]
        end
      end
    end
  end
end
