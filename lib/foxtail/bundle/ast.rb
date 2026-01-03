# frozen_string_literal: true

module Foxtail
  class Bundle
    # Ruby port of fluent-bundle/src/ast.ts type system
    # Data class-based implementation for immutability and type safety
    module AST
      StringLiteral = Data.define(:value)

      # String literal expression in Fluent patterns
      # @!attribute value [r] [String] The string value
      class StringLiteral
        # @param value [#to_s] The string value (will be converted to String)
        def initialize(value:) = super(value: value.to_s)

        # @return [String] The AST node type identifier
        def type = "str"
      end

      NumberLiteral = Data.define(:value, :precision)

      # Number literal expression in Fluent patterns
      # @!attribute value [r] [Float] The numeric value
      # @!attribute precision [r] [Integer] Number of decimal places
      class NumberLiteral
        # @param value [Numeric, String] The numeric value (will be converted to Float)
        # @param precision [Integer] Number of decimal places (default: 0)
        def initialize(value:, precision: 0) = super(value: Float(value), precision: Integer(precision))

        # @return [String] The AST node type identifier
        def type = "num"
      end

      VariableReference = Data.define(:name)

      # Variable reference expression ($variable) in Fluent patterns
      # @!attribute name [r] [String] The variable name (without $ prefix)
      class VariableReference
        # @param name [#to_s] The variable name (will be converted to String)
        def initialize(name:) = super(name: name.to_s)

        # @return [String] The AST node type identifier
        def type = "var"
      end

      TermReference = Data.define(:name, :attr, :args)

      # Term reference expression (-term) in Fluent patterns
      # @!attribute name [r] [String] The term name (without - prefix)
      # @!attribute attr [r] [String, nil] The attribute name if accessing an attribute
      # @!attribute args [r] [Array] Arguments passed to the term
      class TermReference
        # @param name [#to_s] The term name (will be converted to String)
        # @param attr [#to_s, nil] The attribute name (default: nil)
        # @param args [Array] Arguments passed to the term (default: [])
        def initialize(name:, attr: nil, args: []) = super(name: name.to_s, attr: attr&.to_s, args:)

        # @return [String] The AST node type identifier
        def type = "term"
      end

      MessageReference = Data.define(:name, :attr)

      # Message reference expression (message) in Fluent patterns
      # @!attribute name [r] [String] The message identifier
      # @!attribute attr [r] [String, nil] The attribute name if accessing an attribute
      class MessageReference
        # @param name [#to_s] The message identifier (will be converted to String)
        # @param attr [#to_s, nil] The attribute name (default: nil)
        def initialize(name:, attr: nil) = super(name: name.to_s, attr: attr&.to_s)

        # @return [String] The AST node type identifier
        def type = "mesg"
      end

      FunctionReference = Data.define(:name, :args)

      # Function call expression (FUNCTION()) in Fluent patterns
      # @!attribute name [r] [String] The function name (uppercase by convention)
      # @!attribute args [r] [Array] Function arguments (positional and named)
      class FunctionReference
        # @param name [#to_s] The function name (will be converted to String)
        # @param args [Array] Function arguments (default: [])
        def initialize(name:, args: []) = super(name: name.to_s, args:)

        # @return [String] The AST node type identifier
        def type = "func"
      end

      NamedArgument = Data.define(:name, :value)

      # Named argument in function calls (key: value)
      # @!attribute name [r] [String] The argument name
      # @!attribute value [r] The argument value expression
      class NamedArgument
        # @param name [#to_s] The argument name (will be converted to String)
        # @param value The argument value expression
        def initialize(name:, value:) = super(name: name.to_s, value:)

        # @return [String] The AST node type identifier
        def type = "narg"
      end

      SelectExpression = Data.define(:selector, :variants, :star)

      # Select expression for pluralization and variants
      # @!attribute selector [r] The expression to match against
      # @!attribute variants [r] [Array<Variant>] The variant branches
      # @!attribute star [r] [Integer] Index of the default variant
      class SelectExpression
        # @param selector The expression to match against
        # @param variants [Array<Variant>] The variant branches
        # @param star [Integer] Index of the default variant (default: 0)
        def initialize(selector:, variants:, star: 0) = super

        # @return [String] The AST node type identifier
        def type = "select"
      end

      # Variant for select expressions (no type field, no special initialization)
      Variant = Data.define(:key, :value)

      Message = Data.define(:id, :value, :attributes)

      # Message entry in fluent-bundle compatible format
      # @!attribute id [r] [String] The message identifier
      # @!attribute value [r] The message pattern (String or Array)
      # @!attribute attributes [r] [Hash, nil] Message attributes
      class Message
        # @param id [#to_s] The message identifier (will be converted to String)
        # @param value The message pattern (default: nil)
        # @param attributes [Hash, nil] Message attributes (default: nil)
        def initialize(id:, value: nil, attributes: nil) = super(id: id.to_s, value:, attributes:)

        # @return [String] The AST node type identifier
        def type = "message"
      end

      Term = Data.define(:id, :value, :attributes)

      # Term entry in fluent-bundle compatible format
      # @!attribute id [r] [String] The term identifier (with - prefix)
      # @!attribute value [r] The term pattern (String or Array)
      # @!attribute attributes [r] [Hash, nil] Term attributes
      class Term
        # @param id [#to_s] The term identifier (- prefix will be added if missing)
        # @param value The term pattern
        # @param attributes [Hash, nil] Term attributes (default: nil)
        def initialize(id:, value:, attributes: nil)
          term_id = id.to_s
          term_id = "-#{term_id}" unless term_id.start_with?("-")
          super(id: term_id, value:, attributes:)
        end

        # @return [String] The AST node type identifier
        def type = "term"
      end

      # Type checking helpers (following TypeScript union types)

      # Check if node is a literal (string or number)
      def self.literal?(node) = node.is_a?(StringLiteral) || node.is_a?(NumberLiteral)

      # Check if node is an expression
      def self.expression?(node)
        return true if literal?(node)

        node.is_a?(VariableReference) ||
          node.is_a?(TermReference) ||
          node.is_a?(MessageReference) ||
          node.is_a?(FunctionReference) ||
          node.is_a?(SelectExpression)
      end

      # Check if node can be a pattern element
      def self.pattern_element?(node) = node.is_a?(String) || expression?(node)

      # Check if node is a complex pattern (array of pattern elements)
      def self.complex_pattern?(node) = node.is_a?(Array) && node.all? {|el| pattern_element?(el) }

      # Check if node is any valid pattern
      def self.pattern?(node) = node.is_a?(String) || complex_pattern?(node)
    end
  end
end
