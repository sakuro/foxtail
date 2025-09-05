# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Variant < SyntaxNode
        attr_accessor :key, :value, :default

        def initialize(key, value, default = false)
          super()
          @key = key
          @value = value
          @default = default
        end
      end
    end
  end
end
