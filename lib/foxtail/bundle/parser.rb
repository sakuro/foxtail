# frozen_string_literal: true

module Foxtail
  class Bundle
    # Lightweight runtime parser for FTL resources.
    # Equivalent to fluent-bundle's FluentResource parser.
    #
    # This parser is optimized for runtime performance and produces
    # Bundle::AST structures directly. Unlike Syntax::Parser, it:
    # - Does not track source positions
    # - Does not preserve comments
    # - Uses error recovery to skip invalid entries
    # - Produces `String | Array` patterns directly
    #
    # For validation and tooling, use Syntax::Parser instead.
    class Parser
      # Internal parse error for control flow
      class ParseError < StandardError; end

      # Regex patterns (equivalent to fluent-bundle/src/resource.ts)
      RE_MESSAGE_START = /^(-?[a-zA-Z][\w-]*) *= */m
      RE_ATTRIBUTE_START = /\.([a-zA-Z][\w-]*) *= */
      RE_VARIANT_START = /\*?\[/
      RE_NUMBER_LITERAL = /(-?[0-9]+(?:\.([0-9]+))?)/
      RE_IDENTIFIER = /([a-zA-Z][\w-]*)/
      RE_REFERENCE = /([$-])?([a-zA-Z][\w-]*)(?:\.([a-zA-Z][\w-]*))?/
      RE_FUNCTION_NAME = /^[A-Z][A-Z0-9_-]*$/
      RE_TEXT_RUN = /([^{}\n\r]+)/
      RE_STRING_RUN = /([^\\"\n\r]*)/
      RE_STRING_ESCAPE = /\\([\\"])/
      RE_UNICODE_ESCAPE = /\\u([a-fA-F0-9]{4})|\\U([a-fA-F0-9]{6})/
      RE_LEADING_NEWLINES = /^\n+/
      RE_TRAILING_SPACES = / +$/
      RE_BLANK_LINES = / *\r?\n/
      RE_INDENT = /( *)$/

      # Token patterns
      TOKEN_BRACE_OPEN = /\{\s*/
      TOKEN_BRACE_CLOSE = /\s*\}/
      TOKEN_BRACKET_OPEN = /\[\s*/
      TOKEN_BRACKET_CLOSE = /\s*\] */
      TOKEN_PAREN_OPEN = /\s*\(\s*/
      TOKEN_ARROW = /\s*->\s*/
      TOKEN_COLON = /\s*:\s*/
      TOKEN_COMMA = /\s*,?\s*/
      TOKEN_BLANK = /\s+/

      private_constant :RE_MESSAGE_START, :RE_ATTRIBUTE_START, :RE_VARIANT_START
      private_constant :RE_NUMBER_LITERAL, :RE_IDENTIFIER, :RE_REFERENCE, :RE_FUNCTION_NAME
      private_constant :RE_TEXT_RUN, :RE_STRING_RUN, :RE_STRING_ESCAPE, :RE_UNICODE_ESCAPE
      private_constant :RE_LEADING_NEWLINES, :RE_TRAILING_SPACES, :RE_BLANK_LINES, :RE_INDENT
      private_constant :TOKEN_BRACE_OPEN, :TOKEN_BRACE_CLOSE, :TOKEN_BRACKET_OPEN
      private_constant :TOKEN_BRACKET_CLOSE, :TOKEN_PAREN_OPEN, :TOKEN_ARROW
      private_constant :TOKEN_COLON, :TOKEN_COMMA, :TOKEN_BLANK

      # Parse FTL source into an array of messages and terms
      # @param source [String] FTL source text
      # @return [Array<AST::Message, AST::Term>] Parsed entries
      def parse(source)
        @source = source
        @cursor = 0
        @body = []

        # Iterate over message/term starts
        source.scan(RE_MESSAGE_START) do |match|
          id = match[0]
          @cursor = Regexp.last_match.end(0)

          begin
            @body << parse_message(id)
          rescue ParseError
            # Skip to next entry on error
            next
          end
        end

        @body
      end

      # Test if regex matches at current cursor position
      private def matches?(regex)
        @source[@cursor..].match?(/\A#{regex.source}/)
      end

      # Consume a single character if it matches
      private def consume_char(character, required: false)
        if @source[@cursor] == character
          @cursor += 1
          return true
        end

        raise ParseError, "Expected #{character}" if required

        false
      end

      # Consume a token (regex) if it matches
      private def consume_token(regex, required: false)
        if (match = @source[@cursor..].match(/\A#{regex.source}/))
          @cursor += match[0].length
          return true
        end

        raise ParseError, "Expected #{regex}" if required

        false
      end

      # Match a regex and return captures, advancing cursor
      private def match_regex(regex)
        match = @source[@cursor..].match(/\A#{regex.source}/)
        raise ParseError, "Expected #{regex}" unless match

        @cursor += match[0].length
        match
      end

      # Match a regex and return the first capture group
      private def match_capture(regex) = match_regex(regex)[1]

      # Parse a message or term
      private def parse_message(id)
        value = parse_pattern
        attributes = parse_attributes

        if value.nil? && (attributes.nil? || attributes.empty?)
          raise ParseError, "Expected message value or attributes"
        end

        if id.start_with?("-")
          AST::Term[id:, value:, attributes:]
        else
          AST::Message[id:, value:, attributes:]
        end
      end

      # Skip blank lines and check if there's an attribute
      private def skip_blank_and_check_attribute
        start = @cursor

        # Skip newlines
        while @source[@cursor] == "\n" || @source[@cursor] == "\r"
          @cursor += 2 if @source[@cursor] == "\r" && @source[@cursor + 1] == "\n"
          @cursor += 1 unless @source[@cursor - 1] == "\n" && @source[@cursor - 2] == "\r"
        end

        # Skip spaces (indentation)
        @cursor += 1 while @source[@cursor] == " "

        # Check if we have an attribute start
        if matches?(RE_ATTRIBUTE_START)
          true
        else
          @cursor = start
          false
        end
      end

      # Parse attributes (.attr = value)
      private def parse_attributes
        attrs = {}

        while skip_blank_and_check_attribute
          name = match_capture(RE_ATTRIBUTE_START)
          value = parse_pattern

          raise ParseError, "Expected attribute value" if value.nil?

          attrs[name] = value
        end

        attrs.empty? ? nil : attrs
      end

      # Parse a pattern (simple text or complex array)
      private def parse_pattern
        first = nil

        # Try to parse simple text on the same line
        first = match_capture(RE_TEXT_RUN) if matches?(RE_TEXT_RUN)

        # If there's a placeable on the first line, parse complex pattern
        if @source[@cursor] == "{" || @source[@cursor] == "}"
          return parse_pattern_elements(first ? [first] : [], Float::INFINITY)
        end

        # Check for indented continuation
        indent = parse_indent
        if indent
          if first
            # Text on first line + indented continuation
            return parse_pattern_elements([first, indent], indent[:length])
          end

          # Block pattern starting on new line
          indent[:value] = indent[:value].sub(RE_LEADING_NEWLINES, "")
          return parse_pattern_elements([indent], indent[:length])
        end

        # Just simple inline text
        return first.sub(RE_TRAILING_SPACES, "") if first

        nil
      end

      # Parse indent (newlines + spaces)
      private def parse_indent
        start = @cursor
        blank = ""

        while @source[@cursor] == "\n" || @source[@cursor] == "\r"
          @cursor += 2 if @source[@cursor] == "\r" && @source[@cursor + 1] == "\n"
          @cursor += 1 unless @source[@cursor - 1] == "\n" && @source[@cursor - 2] == "\r"
          blank += "\n"
        end

        # Count leading spaces
        spaces = ""
        while @source[@cursor] == " "
          spaces += " "
          @cursor += 1
        end

        # Must have at least one space to be an indent
        if spaces.empty?
          @cursor = start
          return nil
        end

        # Check if this continues the pattern
        char = @source[@cursor]
        if char.nil? || char == "\n" || char == "\r"
          # Blank line or continuation
          {value: blank + spaces, length: spaces.length}
        elsif char == "}" || char == "." || char == "[" || char == "*"
          # Special characters that end patterns
          @cursor = start
          nil
        else
          # Continuation
          {value: blank + spaces, length: spaces.length}
        end
      end

      # Parse complex pattern elements
      private def parse_pattern_elements(elements, common_indent)
        loop do
          if matches?(RE_TEXT_RUN)
            elements << match_capture(RE_TEXT_RUN)
            next
          end

          if @source[@cursor] == "{"
            elements << parse_placeable
            next
          end

          raise ParseError, "Unbalanced closing brace" if @source[@cursor] == "}"

          indent = parse_indent
          if indent
            elements << indent
            common_indent = [common_indent, indent[:length]].min
            next
          end

          break
        end

        # Trim trailing spaces from last text element
        elements[-1] = elements.last.sub(RE_TRAILING_SPACES, "") if elements.last.is_a?(String)

        # Dedent and flatten
        dedent_elements(elements, common_indent)
      end

      # Dedent pattern elements by common indent
      private def dedent_elements(elements, common_indent)
        baked = []
        elements.each do |element|
          if element.is_a?(Hash) && element[:value]
            # Dedent indented lines
            value = element[:value]
            dedented = safe_dedent(value, common_indent)
            baked << dedented unless dedented.empty?
          elsif element
            baked << element
          end
        end
        baked
      end

      # Safely dedent a value by common indent, returning original if too short
      private def safe_dedent(value, common_indent)
        end_index = value.length - common_indent
        return value if end_index <= 0

        value[0...end_index]
      end

      # Parse a placeable expression
      private def parse_placeable
        consume_token(TOKEN_BRACE_OPEN, required: true)

        selector = parse_inline_expression

        return selector if consume_token(TOKEN_BRACE_CLOSE)

        if consume_token(TOKEN_ARROW)
          variants_result = parse_variants
          consume_token(TOKEN_BRACE_CLOSE, required: true)
          return AST::SelectExpression[
            selector:,
            variants: variants_result[:variants],
            star: variants_result[:star]
          ]
        end

        raise ParseError, "Unclosed placeable"
      end

      # Parse an inline expression
      private def parse_inline_expression
        return parse_placeable if @source[@cursor] == "{"

        if matches?(RE_REFERENCE)
          match = match_regex(RE_REFERENCE)
          sigil = match[1]
          name = match[2]
          attr = match[3]

          return AST::VariableReference[name:] if sigil == "$"

          if consume_token(TOKEN_PAREN_OPEN)
            args = parse_arguments

            return AST::TermReference[name:, attr:, args:] if sigil == "-"

            return AST::FunctionReference[name:, args:] if RE_FUNCTION_NAME.match?(name)

            raise ParseError, "Function names must be all upper-case"
          end

          return AST::TermReference[name:, attr:, args: []] if sigil == "-"

          return AST::MessageReference[name:, attr:]
        end

        parse_literal
      end

      # Parse function/term arguments
      private def parse_arguments
        args = []

        loop do
          case @source[@cursor]
          when ")"
            @cursor += 1
            return args
          when nil
            raise ParseError, "Unclosed argument list"
          end

          args << parse_argument
          consume_token(TOKEN_COMMA)
        end
      end

      # Parse a single argument
      private def parse_argument
        expr = parse_inline_expression

        if expr.is_a?(AST::MessageReference) && consume_token(TOKEN_COLON)
          # Named argument
          return AST::NamedArgument[name: expr.name, value: parse_literal]
        end

        expr
      end

      # Skip blank lines and check if there's a variant
      private def skip_blank_and_check_variant
        start = @cursor

        # Skip newlines
        while @source[@cursor] == "\n" || @source[@cursor] == "\r"
          @cursor += 2 if @source[@cursor] == "\r" && @source[@cursor + 1] == "\n"
          @cursor += 1 unless @source[@cursor - 1] == "\n" && @source[@cursor - 2] == "\r"
        end

        # Skip spaces (indentation)
        @cursor += 1 while @source[@cursor] == " "

        # Check if we have a variant start
        if matches?(RE_VARIANT_START)
          true
        else
          @cursor = start
          false
        end
      end

      # Parse variants for select expression
      private def parse_variants
        variants = []
        count = 0
        star = nil

        while skip_blank_and_check_variant
          star = count if consume_char("*")

          key = parse_variant_key
          value = parse_pattern

          raise ParseError, "Expected variant value" if value.nil?

          variants << AST::Variant[key:, value:]
          count += 1
        end

        raise ParseError, "Expected at least one variant" if count == 0
        raise ParseError, "Expected default variant" if star.nil?

        {variants:, star:}
      end

      # Parse a variant key
      private def parse_variant_key
        consume_token(TOKEN_BRACKET_OPEN, required: true)

        key = if matches?(RE_NUMBER_LITERAL)
                parse_number_literal
              else
                AST::StringLiteral[value: match_capture(RE_IDENTIFIER)]
              end

        consume_token(TOKEN_BRACKET_CLOSE, required: true)
        key
      end

      # Parse a literal
      private def parse_literal
        return parse_number_literal if matches?(RE_NUMBER_LITERAL)

        return parse_string_literal if @source[@cursor] == '"'

        raise ParseError, "Invalid expression"
      end

      # Parse a number literal
      private def parse_number_literal
        match = match_regex(RE_NUMBER_LITERAL)
        value_str = match[1]
        fraction = match[2] || ""
        precision = fraction.length

        AST::NumberLiteral[value: Float(value_str), precision:]
      end

      # Parse a string literal
      private def parse_string_literal
        @cursor += 1 # Skip opening quote
        value = ""

        loop do
          if (match = @source[@cursor..].match(/\A#{RE_STRING_RUN.source}/))
            value += match[0]
            @cursor += match[0].length
          end

          case @source[@cursor]
          when '"'
            @cursor += 1
            break
          when "\\"
            value += parse_escape_sequence
          else
            raise ParseError, "Unclosed string literal"
          end
        end

        AST::StringLiteral[value:]
      end

      # Parse an escape sequence
      private def parse_escape_sequence
        if (match = @source[@cursor..].match(/\A#{RE_UNICODE_ESCAPE.source}/))
          @cursor += match[0].length
          code = match[1] || match[2]
          return [code.to_i(16)].pack("U")
        end

        if (match = @source[@cursor..].match(/\A#{RE_STRING_ESCAPE.source}/))
          @cursor += match[0].length
          return match[1]
        end

        raise ParseError, "Invalid escape sequence"
      end
    end
  end
end
