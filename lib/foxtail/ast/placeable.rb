# frozen_string_literal: true

module Foxtail
  module AST
    # Represents a placeable in a pattern
    class Placeable < Node
      attr_accessor :expression

      def initialize(expression)
        super()
        @expression = expression
      end
    end
  end
end
