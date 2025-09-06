# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      # Represents attributes of messages and terms (e.g., .attr = value)
      class Attribute < SyntaxNode
        attr_accessor :id
        attr_accessor :value

        def initialize(id, value)
          super()
          @id = id
          @value = value
        end
      end
    end
  end
end
