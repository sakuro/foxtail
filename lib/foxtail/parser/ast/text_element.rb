# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class TextElement < SyntaxNode
        attr_accessor :value

        def initialize(value)
          super()
          @value = value
        end
      end
    end
  end
end
