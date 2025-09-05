# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class MessageReference < SyntaxNode
        attr_accessor :id, :attribute

        def initialize(id, attribute = nil)
          super()
          @id = id
          @attribute = attribute
        end
      end
    end
  end
end
