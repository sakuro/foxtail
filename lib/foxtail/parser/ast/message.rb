# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      # Represents a Fluent message with an identifier, optional value pattern,
      # attributes, and an optional comment
      class Message < SyntaxNode
        attr_accessor :id
        attr_accessor :value
        attr_accessor :attributes
        attr_accessor :comment

        def initialize(id, value=nil, attributes=[], comment=nil)
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
