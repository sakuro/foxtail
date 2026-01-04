# frozen_string_literal: true

module Foxtail
  class Bundle
    # Convert Parser::AST to Bundle::AST
    # This is the key bridge between parsing and runtime
    class ASTConverter
      # Reference to Bundle::AST for convenience
      AST = Foxtail::Bundle::AST
      private_constant :AST

      # @param skip_junk [Boolean] Skip invalid entries (default: true)
      # @param skip_comments [Boolean] Skip comment entries (default: true)
      def initialize(skip_junk: true, skip_comments: true)
        @skip_junk = skip_junk
        @skip_comments = skip_comments
        @errors = []
      end

      attr_reader :errors

      # Parser::AST::Resource → Array of Bundle::AST entries
      def convert_resource(parser_resource)
        entries = []

        parser_resource.body.each do |entry|
          case entry
          when Foxtail::Syntax::Parser::AST::Message
            entries << convert_message(entry)
          when Foxtail::Syntax::Parser::AST::Term
            entries << convert_term(entry)
          when Foxtail::Syntax::Parser::AST::Junk
            handle_junk(entry) unless @skip_junk
          when Foxtail::Syntax::Parser::AST::Comment
            handle_comment(entry) unless @skip_comments
          end
        end

        entries
      end

      # Convert Parser::AST::Message to Bundle::AST message
      def convert_message(parser_message)
        AST::Message[
          id: parser_message.id.name,
          value: convert_pattern(parser_message.value),
          attributes: convert_attributes(parser_message.attributes)
        ]
      end

      # Convert Parser::AST::Term to Bundle::AST term
      def convert_term(parser_term)
        AST::Term[
          id: parser_term.id.name,
          value: convert_pattern(parser_term.value),
          attributes: convert_attributes(parser_term.attributes)
        ]
      end

      # Convert Parser::AST::Pattern to Bundle::AST pattern
      # Following fluent-bundle/src/resource.ts parsePattern logic:
      # - Simple inline text → string
      # - Text with placeables or multiline → array
      private def convert_pattern(parser_pattern)
        case parser_pattern
        when String
          parser_pattern
        when Foxtail::Syntax::Parser::AST::Pattern
          converted = convert_complex_pattern(parser_pattern.elements)

          # Apply fluent-bundle logic:
          # For truly simple single-line text without complex structure → return string
          # For anything else (multiline, multiple elements, complex structure) → return array
          if converted.is_a?(String) && !converted.include?("\n")
            converted
          elsif converted.is_a?(Array) && converted.length == 1 &&
                converted.first.is_a?(String) && !converted.first.include?("\n") &&
                pattern_is_simple_inline?(parser_pattern)

            converted.first
          else
            converted
          end
        end
      end

      # Check if the original pattern was defined as simple inline text
      private def pattern_is_simple_inline?(pattern)
        # This is a heuristic - in a full implementation, we'd need to track
        # whether the pattern was defined on the same line as the message ID
        # For now, use a simple approach
        pattern.elements.length == 1 &&
          pattern.elements.first.is_a?(Foxtail::Syntax::Parser::AST::TextElement) &&
          !pattern.elements.first.value.include?("\n")
      end

      # Check if this is a simple inline pattern (should be string, not array)
      private def simple_inline_pattern?(elements)
        # Only return string for truly simple inline patterns
        # fluent-bundle uses arrays for any complex patterns including multiline
        elements.is_a?(String) && !elements.include?("\n")
      end

      # Convert array of pattern elements
      # Always return array for complex patterns - fluent-bundle keeps
      # multi-element patterns as arrays even if they're all strings
      private def convert_complex_pattern(elements)
        elements.flat_map {|element| convert_pattern_element(element) }
      end

      # Convert individual pattern element
      private def convert_pattern_element(element)
        case element
        when String
          element
        when Foxtail::Syntax::Parser::AST::TextElement
          # Process escape sequences and then split multiline text
          split_multiline_text(process_escape_sequences(element.value))
        when Foxtail::Syntax::Parser::AST::Placeable
          convert_expression(element.expression)
        else
          element.to_s
        end
      end

      # Split multiline text into separate elements like fluent-bundle does
      # Process escape sequences in text to match fluent-bundle behavior
      private def process_escape_sequences(text)
        # Ensure text is valid UTF-8 before processing
        text = text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

        # Handle Unicode escape sequences first
        text = text.gsub(/\\u([0-9a-fA-F]{4})/) {|_match| [$1.to_i(16)].pack("U") }

        # Handle other escape sequences
        text.gsub(/\\(.)/) do |match|
          case $1
          when '"'
            '"'
          when "\\"
            "\\"
          when "n"
            "\n"
          when "r"
            "\r"
          when "t"
            "\t"
          else
            # For other escape sequences, keep as-is
            match
          end
        end
      rescue ArgumentError
        # If we still have encoding issues, return the original text
        text
      end

      # Split multiline text into separate elements like fluent-bundle does
      private def split_multiline_text(text)
        # Split on sequences of newlines, but preserve the newlines as separate elements
        if text.include?("\n")
          parts = text.split(/(\n+)/).reject(&:empty?)
          return parts if parts.length > 1
        end
        text
      end

      # Convert Parser::AST expression to Bundle::AST expression
      private def convert_expression(expr)
        case expr
        when Foxtail::Syntax::Parser::AST::VariableReference
          AST::VariableReference[name: expr.id.name]

        when Foxtail::Syntax::Parser::AST::MessageReference
          AST::MessageReference[name: expr.id.name, attr: expr.attribute&.name]

        when Foxtail::Syntax::Parser::AST::TermReference
          AST::TermReference[name: expr.id.name, attr: expr.attribute&.name]

        when Foxtail::Syntax::Parser::AST::FunctionReference
          # Convert function arguments - both positional and named
          args = []

          if expr.arguments
            # Add positional arguments
            if expr.arguments.positional
              args.concat(expr.arguments.positional.map {|arg| convert_expression(arg) })
            end

            # Add named arguments
            if expr.arguments.named
              expr.arguments.named.each do |named_arg|
                args << AST::NamedArgument[name: named_arg.name.name, value: convert_expression(named_arg.value)]
              end
            end
          end

          AST::FunctionReference[name: expr.id.name, args:]

        when Foxtail::Syntax::Parser::AST::SelectExpression
          selector = convert_expression(expr.selector)
          variants = expr.variants.map {|variant|
            key = convert_literal(variant.key)
            # Variant values stay as strings in Bundle format, not arrays
            value = convert_variant_pattern(variant.value)
            AST::Variant[key:, value:]
          }
          star_index = expr.variants.find_index(&:default) || 0
          AST::SelectExpression[selector:, variants:, star: star_index]

        when Foxtail::Syntax::Parser::AST::StringLiteral
          AST::StringLiteral[value: expr.value]

        when Foxtail::Syntax::Parser::AST::NumberLiteral
          AST::NumberLiteral[value: expr.value]

        else
          # Unknown expression - convert to string literal as fallback
          AST::StringLiteral[value: expr.to_s]
        end
      end

      # Convert literals (for SelectExpression variant keys)
      private def convert_literal(literal)
        case literal
        when Foxtail::Syntax::Parser::AST::StringLiteral
          AST::StringLiteral[value: literal.value]
        when Foxtail::Syntax::Parser::AST::NumberLiteral
          AST::NumberLiteral[value: literal.value]
        when Foxtail::Syntax::Parser::AST::Identifier
          AST::StringLiteral[value: literal.name]
        else
          AST::StringLiteral[value: literal.to_s]
        end
      end

      # Convert attributes hash (returns nil if empty)
      private def convert_attributes(parser_attributes)
        return nil if parser_attributes.empty?

        attributes = {}
        parser_attributes.each do |attr|
          attributes[attr.id.name] = convert_attribute_pattern(attr.value)
        end
        attributes
      end

      # Convert attribute pattern (attributes stay as strings, not arrays)
      private def convert_attribute_pattern(parser_pattern)
        case parser_pattern
        when String
          parser_pattern
        when Foxtail::Syntax::Parser::AST::Pattern
          convert_attribute_complex_pattern(parser_pattern.elements)
        end
      end

      # Convert attribute complex pattern to string
      private def convert_attribute_complex_pattern(elements) = elements.map {|element| convert_pattern_element(element) }.join

      # Convert variant pattern (SelectExpression variant values stay as strings)
      private def convert_variant_pattern(parser_pattern)
        case parser_pattern
        when String
          parser_pattern
        when Foxtail::Syntax::Parser::AST::Pattern
          convert_variant_complex_pattern(parser_pattern.elements)
        end
      end

      # Convert variant complex pattern
      private def convert_variant_complex_pattern(elements)
        converted = elements.map {|element|
          case element
          when String
            element
          when Foxtail::Syntax::Parser::AST::TextElement
            element.value
          when Foxtail::Syntax::Parser::AST::Placeable
            convert_expression(element.expression)
          else
            element.to_s
          end
        }

        # If contains expressions, keep as array; if all strings, join
        converted.any? {|el| AST.expression?(el) } ? converted : converted.join
      end

      # Handle junk entries
      private def handle_junk(junk)
        @errors << AST::Junk[content: junk.content, annotations: junk.annotations.map(&:to_h)]
      end

      # Handle comment entries
      private def handle_comment(comment)
        @errors << AST::Comment[content: comment.content]
      end
    end
  end
end
