# frozen_string_literal: true

module Fantail
  module Syntax
    class Parser
      module AST
        # Represents identifiers used for messages, terms, attributes, and function names
        class Identifier < SyntaxNode
          attr_accessor :name

          def initialize(name)
            super()
            @name = name
          end
        end
      end
    end
  end
end
