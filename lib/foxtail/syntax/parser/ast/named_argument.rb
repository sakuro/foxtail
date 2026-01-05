# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
        # Represents named arguments in function calls (e.g., arg: value)
        class NamedArgument < SyntaxNode
          attr_accessor :name
          attr_accessor :value

          def initialize(name, value)
            super()
            @name = name
            @value = value
          end
        end
      end
    end
  end
end
