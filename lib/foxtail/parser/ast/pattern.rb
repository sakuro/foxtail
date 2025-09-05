# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Pattern < SyntaxNode
        attr_accessor :elements

        def initialize(elements)
          super()
          @elements = elements
        end
      end
    end
  end
end
