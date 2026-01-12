# frozen_string_literal: true

module Fantail
  module Syntax
    class Parser
      module AST
        # Represents references to variables passed as arguments (e.g., $variable)
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
end
