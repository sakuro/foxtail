# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Term < SyntaxNode
        attr_accessor :id, :value, :attributes, :comment

        def initialize(id, value, attributes = [], comment = nil)
          super()
          @id = id
          @value = value
          @attributes = attributes
          @comment = comment
        end
      end
    end
  end
end
