# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Attribute < SyntaxNode
        attr_accessor :id, :value

        def initialize(id, value)
          super()
          @id = id
          @value = value
        end
      end
    end
  end
end
