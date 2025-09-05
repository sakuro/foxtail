# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class CallArguments < SyntaxNode
        attr_accessor :positional, :named

        def initialize(positional = [], named = [])
          super()
          @positional = positional
          @named = named
        end
      end
    end
  end
end
