# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
      # Represents select expressions for conditional message variants
      class SelectExpression < SyntaxNode
        attr_accessor :selector
        attr_accessor :variants

        def initialize(selector, variants)
          super()
          @selector = selector
          @variants = variants
        end
      end
    end
  end
end
end
