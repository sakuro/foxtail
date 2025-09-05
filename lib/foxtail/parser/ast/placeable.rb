# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
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
