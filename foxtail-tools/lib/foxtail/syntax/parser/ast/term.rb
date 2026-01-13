# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
        # Represents a Fluent term with an identifier, value pattern,
        # optional attributes, and an optional comment
        class Term < SyntaxNode
          attr_accessor :id
          attr_accessor :value
          attr_accessor :attributes
          attr_accessor :comment

          def initialize(id, value, attributes=[], comment=nil)
            super()
            @id = id
            @value = value
            @attributes = attributes
            @comment = comment
          end

          def children = [id, value, *attributes, comment].compact
        end
      end
    end
  end
end
