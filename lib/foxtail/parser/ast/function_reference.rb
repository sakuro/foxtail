# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class FunctionReference < SyntaxNode
        attr_accessor :id, :arguments

        def initialize(id, arguments = nil)
          super()
          @id = id
          @arguments = arguments
        end
      end
    end
  end
end
