# frozen_string_literal: true

module Fantail
  module Syntax
    class Parser
      module AST
        # Represents references to messages with optional attribute access
        class MessageReference < SyntaxNode
          attr_accessor :id
          attr_accessor :attribute

          def initialize(id, attribute=nil)
            super()
            @id = id
            @attribute = attribute
          end
        end
      end
    end
  end
end
