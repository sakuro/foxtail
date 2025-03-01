# frozen_string_literal: true

require_relative "base"

module Foxtail
  module AST
    # VariableReference node representing a variable reference in FTL
    class VariableReference < SyntaxNode
      attr_reader :id

      def initialize(id)
        super()
        @id = id
      end
    end

    # MessageReference node representing a message reference in FTL
    class MessageReference < SyntaxNode
      attr_reader :id
      attr_reader :attribute

      def initialize(id, attribute=nil)
        super()
        @id = id
        @attribute = attribute
      end
    end

    # TermReference node representing a term reference in FTL
    class TermReference < SyntaxNode
      attr_reader :id
      attr_reader :attribute
      attr_reader :arguments

      def initialize(id, attribute=nil, arguments=nil)
        super()
        @id = id
        @attribute = attribute
        @arguments = arguments
      end
    end

    # SelectExpression node representing a select expression in FTL
    class SelectExpression < SyntaxNode
      attr_reader :selector
      attr_reader :variants

      def initialize(selector, variants)
        super()
        @selector = selector
        @variants = variants
      end
    end

    # Variant node representing a variant in FTL
    class Variant < SyntaxNode
      attr_reader :key
      attr_reader :value
      attr_reader :default

      def initialize(key, value, default: false)
        super()
        @key = key
        @value = value
        @default = default
      end
    end

    # NumberLiteral node representing a number literal in FTL
    class NumberLiteral < SyntaxNode
      attr_reader :value

      def initialize(value)
        super()
        @value = value
      end
    end

    # StringLiteral node representing a string literal in FTL
    class StringLiteral < SyntaxNode
      attr_reader :value

      def initialize(value)
        super()
        @value = value
      end
    end

    # FunctionReference node representing a function reference in FTL
    class FunctionReference < SyntaxNode
      attr_reader :id
      attr_reader :arguments

      def initialize(id, arguments)
        super()
        @id = id
        @arguments = arguments
      end
    end

    # CallArguments node representing call arguments in FTL
    class CallArguments < SyntaxNode
      attr_reader :positional
      attr_reader :named

      def initialize(positional=[], named=[])
        super()
        @positional = positional
        @named = named
      end
    end

    # NamedArgument node representing a named argument in FTL
    class NamedArgument < SyntaxNode
      attr_reader :name
      attr_reader :value

      def initialize(name, value)
        super()
        @name = name
        @value = value
      end
    end
  end
end
