# frozen_string_literal: true

require_relative "base"

module Foxtail
  module AST
    # Pattern node representing a pattern in FTL
    class Pattern < SyntaxNode
      attr_reader :elements

      def initialize(elements=[])
        super()
        @elements = elements
      end
    end

    # TextElement node representing a text element in FTL
    class TextElement < SyntaxNode
      attr_reader :value

      def initialize(value)
        super()
        @value = value
      end
    end

    # Placeable node representing a placeable in FTL
    class Placeable < SyntaxNode
      attr_reader :expression

      def initialize(expression)
        super()
        @expression = expression
      end
    end
  end
end
