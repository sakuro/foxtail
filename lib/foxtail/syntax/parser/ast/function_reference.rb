# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
      # Represents function calls with optional arguments
      class FunctionReference < SyntaxNode
        attr_accessor :id
        attr_accessor :arguments

        def initialize(id, arguments=nil)
          super()
          @id = id
          @arguments = arguments
        end
      end
    end
  end
end
end
