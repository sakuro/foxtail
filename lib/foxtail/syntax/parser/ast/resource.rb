# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
        # Represents a Fluent resource containing messages, terms, and comments
        # This is the root node of a parsed Fluent file
        class Resource < SyntaxNode
          attr_accessor :body

          def initialize(body=[])
            super()
            @body = body
          end
        end
      end
    end
  end
end
