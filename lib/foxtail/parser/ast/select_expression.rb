# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class SelectExpression < SyntaxNode
        attr_accessor :selector, :variants

        def initialize(selector, variants)
          super()
          @selector = selector
          @variants = variants
        end
      end
    end
  end
end
