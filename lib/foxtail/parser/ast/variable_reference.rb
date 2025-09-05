# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class VariableReference < SyntaxNode
        attr_accessor :id

        def initialize(id)
          super()
          @id = id
        end
      end
    end
  end
end
