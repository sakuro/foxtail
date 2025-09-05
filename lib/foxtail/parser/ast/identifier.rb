# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Identifier < SyntaxNode
        attr_accessor :name

        def initialize(name)
          super()
          @name = name
        end
      end
    end
  end
end
