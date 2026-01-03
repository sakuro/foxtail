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
        # @return [String] The AST node type identifier
        def type = "str"
      end

      NumberLiteral = Data.define(:value, :precision)

      # Number literal expression in Fluent patterns
      # @!attribute value [r] [Float] The numeric value
      # @!attribute precision [r] [Integer] Number of decimal places
      class NumberLiteral
        # @return [String] The AST node type identifier
        def type = "num"
      end

      VariableReference = Data.define(:name)

      # Variable reference expression ($variable) in Fluent patterns
      # @!attribute name [r] [String] The variable name (without $ prefix)
      class VariableReference
        # @return [String] The AST node type identifier
        def type = "var"
      end

      TermReference = Data.define(:name, :attr, :args)

      # Term reference expression (-term) in Fluent patterns
      # @!attribute name [r] [String] The term name (without - prefix)
      # @!attribute attr [r] [String, nil] The attribute name if accessing an attribute
      # @!attribute args [r] [Array] Arguments passed to the term
      class TermReference
        # @return [String] The AST node type identifier
        def type = "term"
      end

      MessageReference = Data.define(:name, :attr)

      # Message reference expression (message) in Fluent patterns
      # @!attribute name [r] [String] The message identifier
      # @!attribute attr [r] [String, nil] The attribute name if accessing an attribute
      class MessageReference
        # @return [String] The AST node type identifier
        def type = "mesg"
      end

      FunctionReference = Data.define(:name, :args)

      # Function call expression (FUNCTION()) in Fluent patterns
      # @!attribute name [r] [String] The function name (uppercase by convention)
      # @!attribute args [r] [Array] Function arguments (positional and named)
      class FunctionReference
        # @return [String] The AST node type identifier
        def type = "func"
      end

      NamedArgument = Data.define(:name, :value)

      # Named argument in function calls (key: value)
      # @!attribute name [r] [String] The argument name
      # @!attribute value [r] The argument value expression
      class NamedArgument
        # @return [String] The AST node type identifier
        def type = "narg"
      end

      SelectExpression = Data.define(:selector, :variants, :star)

      # Select expression for pluralization and variants
      # @!attribute selector [r] The expression to match against
      # @!attribute variants [r] [Array<Variant>] The variant branches
      # @!attribute star [r] [Integer] Index of the default variant
      class SelectExpression
        # @return [String] The AST node type identifier
        def type = "select"
      end

      # Variant for select expressions (no type field)
      Variant = Data.define(:key, :value)

      Message = Data.define(:id, :value, :attributes)

      # Message entry in fluent-bundle compatible format
      # @!attribute id [r] [String] The message identifier
      # @!attribute value [r] The message pattern (String or Array)
      # @!attribute attributes [r] [Hash, nil] Message attributes
      class Message
        # @return [String] The AST node type identifier
        def type = "message"
      end

      Term = Data.define(:id, :value, :attributes)

      # Term entry in fluent-bundle compatible format
      # @!attribute id [r] [String] The term identifier (with - prefix)
      # @!attribute value [r] The term pattern (String or Array)
      # @!attribute attributes [r] [Hash, nil] Term attributes
      class Term
        # @return [String] The AST node type identifier
        def type = "term"
      end

      # Factory methods for convenient node creation
      # Following fluent-bundle/ast.ts type definitions

      # Create a string literal
      def self.str(value) = StringLiteral[value.to_s]

      # Create a number literal
      # @param value [Numeric] The numeric value to convert
      # @param precision [Integer] Number of decimal places (default: 0)
      # @raise [TypeError] when precision is nil or cannot be converted to integer
      def self.num(value, precision: 0) = NumberLiteral[Float(value), Integer(precision)]

      # Create a variable reference
      def self.var(name) = VariableReference[name.to_s]

      # Create a term reference
      def self.term(name, attr: nil, args: []) = TermReference[name.to_s, attr&.to_s, args]

      # Create a message reference
      def self.mesg(name, attr: nil) = MessageReference[name.to_s, attr&.to_s]

      # Create a function reference
      def self.func(name, args: []) = FunctionReference[name.to_s, args]

      # Create a named argument
      def self.narg(name, value) = NamedArgument[name.to_s, value]

      # Create a select expression
      def self.select(selector, variants, star: 0) = SelectExpression[selector, variants, star]

      # Create a variant
      def self.variant(key, value) = Variant[key, value]

      # Create a message entry
      def self.message(id, value: nil, attributes: nil) = Message[id.to_s, value, attributes]

      # Create a term entry
      def self.term_def(id, value, attributes: nil)
        # Ensure term ID has '-' prefix for bundle format
        term_id = id.to_s.start_with?("-") ? id.to_s : "-#{id}"
        Term[term_id, value, attributes]
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
