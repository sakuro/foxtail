# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
      # Represents references to terms with optional attribute access and arguments
      class TermReference < SyntaxNode
        attr_accessor :id
        attr_accessor :attribute
        attr_accessor :arguments

        def initialize(id, attribute=nil, arguments=nil)
          super()
          @id = id
          @attribute = attribute
          @arguments = arguments
        end
      end
    end
  end
end
end
