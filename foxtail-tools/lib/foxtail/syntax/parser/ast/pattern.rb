# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
        # Represents a message or term value pattern consisting of text elements
        # and placeables (expressions within braces)
        class Pattern < SyntaxNode
          attr_accessor :elements

          def initialize(elements)
            super()
            @elements = elements
          end

          def children = elements
        end
      end
    end
  end
end
