# frozen_string_literal: true

module Foxtail
  class Bundle
    # Faithful port of fluent-bundle/src/ast.ts type system
    # Lightweight Hash-based implementation maintaining TypeScript semantics
    module AST
      # Helper methods for creating AST nodes
      # Following fluent-bundle/ast.ts type definitions exactly

      # Create a string literal: StringLiteral
      def self.str(value)
        {"type" => "str", "value" => value.to_s}
      end

      # Create a number literal: NumberLiteral
      # @param value [Numeric] The numeric value to convert
      # @param precision [Integer] Number of decimal places (default: 0)
      # @raise [TypeError] when precision is nil or cannot be converted to integer
      def self.num(value, precision: 0)
        {
          "type" => "num",
          "value" => Float(value),
          "precision" => Integer(precision)
        }
      end

      # Create a variable reference: VariableReference
      def self.var(name)
        {"type" => "var", "name" => name.to_s}
      end

      # Create a term reference: TermReference
      def self.term(name, attr: nil, args: [])
        node = {"type" => "term", "name" => name.to_s}
        node["attr"] = attr&.to_s
        node["args"] = args # Always include args field
        node
      end

      # Create a message reference: MessageReference
      def self.mesg(name, attr: nil)
        node = {"type" => "mesg", "name" => name.to_s}
        node["attr"] = attr&.to_s
        node
      end

      # Create a function reference: FunctionReference
      def self.func(name, args: [])
        node = {"type" => "func", "name" => name.to_s}
        node["args"] = args # Always include args field
        node
      end

      # Create a select expression: SelectExpression
      def self.select(selector, variants, star: 0)
        {
          "type" => "select",
          "selector" => selector,
          "variants" => variants,
          "star" => star
        }
      end

      # Create a variant: Variant
      def self.variant(key, value)
        {"key" => key, "value" => value}
      end

      # Create a message: Message (fluent-bundle compatible format)
      def self.message(id, value: nil, attributes: {})
        node = {"type" => "message", "id" => id.to_s}
        node["value"] = value if value
        node["attributes"] = attributes if attributes&.any?
        node
      end

      # Create a term: Term (fluent-bundle compatible format)
      def self.term_def(id, value, attributes: {})
        # Ensure term ID has '-' prefix for bundle format
        term_id = id.to_s.start_with?("-") ? id.to_s : "-#{id}"
        node = {"type" => "term", "id" => term_id}
        node["value"] = value
        node["attributes"] = attributes if attributes&.any?
        node
      end

      # Type checking helpers (following TypeScript union types)
      # Check if node is a literal (string or number)
      def self.literal?(node)
        node.is_a?(Hash) && %w[str num].include?(node["type"])
      end

      # Check if node is an expression
      def self.expression?(node)
        return true if literal?(node)
        return false unless node.is_a?(Hash)

        %w[var term mesg func select].include?(node["type"])
      end

      # Check if node can be a pattern element
      def self.pattern_element?(node)
        node.is_a?(String) || expression?(node)
      end

      # Check if node is a complex pattern (array of pattern elements)
      def self.complex_pattern?(node)
        node.is_a?(Array) && node.all? {|el| pattern_element?(el) }
      end

      # Check if node is any valid pattern
      def self.pattern?(node)
        node.is_a?(String) || complex_pattern?(node)
      end
    end
  end
end
