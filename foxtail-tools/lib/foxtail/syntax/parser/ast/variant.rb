# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
        # Represents individual variants within select expressions
        class Variant < SyntaxNode
          attr_accessor :key
          attr_accessor :value
          attr_accessor :default

          def initialize(key, value, default: false)
            super()
            @key = key
            @value = value
            @default = default
          end

          def children = [key, value]
        end
      end
    end
  end
end
