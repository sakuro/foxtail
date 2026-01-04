# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
      # Represents function call arguments (both positional and named)
      class CallArguments < SyntaxNode
        attr_accessor :positional
        attr_accessor :named

        def initialize(positional=[], named=[])
          super()
          @positional = positional
          @named = named
        end
      end
    end
  end
end
end
