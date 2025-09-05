# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Message < SyntaxNode
        attr_accessor :id, :value, :attributes, :comment

        def initialize(id, value = nil, attributes = [], comment = nil)
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
