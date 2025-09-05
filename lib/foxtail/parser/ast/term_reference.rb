# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class TermReference < SyntaxNode
        attr_accessor :id, :attribute, :arguments

        def initialize(id, attribute = nil, arguments = nil)
          super()
          @id = id
          @attribute = attribute
          @arguments = arguments
        end
      end
    end
  end
end
