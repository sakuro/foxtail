# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class NamedArgument < SyntaxNode
        attr_accessor :name, :value

        def initialize(name, value)
          super()
          @name = name
          @value = value
        end
      end
    end
  end
end
