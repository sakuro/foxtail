# frozen_string_literal: true

require_relative "base"

module Foxtail
  module AST
    # Message node representing a message in FTL
    class Message < SyntaxNode
      attr_reader :id
      attr_reader :value
      attr_reader :attributes
      attr_accessor :comment

      def initialize(id, value, attributes=[])
        super()
        @id = id
        @value = value
        @attributes = attributes
        @comment = nil
      end
    end

    # Term node representing a term in FTL
    class Term < SyntaxNode
      attr_reader :id
      attr_reader :value
      attr_reader :attributes
      attr_accessor :comment

      def initialize(id, value, attributes=[])
        super()
        @id = id
        @value = value
        @attributes = attributes
        @comment = nil
      end
    end

    # Attribute node representing an attribute in FTL
    class Attribute < SyntaxNode
      attr_reader :id
      attr_reader :value

      def initialize(id, value)
        super()
        @id = id
        @value = value
      end
    end
  end
end
