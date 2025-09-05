# frozen_string_literal: true

require "set"

module Foxtail
  # Ruby equivalent of fluent.js FluentParser
  # Faithfully translates TypeScript parsing logic to Ruby
  class Parser
    TRAILING_WS_RE = /[ \n\r]+$/

    attr_reader :with_spans

    def initialize(with_spans: true)
      @with_spans = with_spans
    end

    # Main entry point - parse FTL source into AST
    def parse(source)
      ps = Stream.new(source)
      ps.skip_blank_block

      entries = []
      last_comment = nil

      while ps.current_char
        entry = get_entry_or_junk(ps)
        blank_lines = ps.skip_blank_block

        # Regular Comments require special logic. Comments may be attached to
        # Messages or Terms if they are followed immediately by them. However
        # they should parse as standalone when they're followed by Junk.
        # Consequently, we only attach Comments once we know that the Message
        # or the Term parsed successfully.
        if entry.is_a?(Comment) && blank_lines.length == 0 && ps.current_char
          # Stash the comment and decide what to do with it in the next pass.
          last_comment = entry
          next
        end

        if last_comment
          if entry.is_a?(Message) || entry.is_a?(Term)
            entry.comment = last_comment
            if @with_spans && entry.span && last_comment.span
              entry.span.start = last_comment.span.start
            end
          else
            entries << last_comment
          end
          # In either case, the stashed comment has been dealt with; clear it.
          last_comment = nil
        end

        # No special logic for other types of entries.
        entries << entry
      end

      res = Resource.new(entries)
      if @with_spans
        res.add_span(0, ps.index)
      end

      res
    end

    # Parse the first Message or Term in source
    def parse_entry(source)
      ps = Stream.new(source)
      ps.skip_blank_block

      while ps.current_char == "#"
        skipped = get_entry_or_junk(ps)
        return skipped if skipped.is_a?(Junk)
        ps.skip_blank_block
      end

      get_entry_or_junk(ps)
    end

    private

    def get_entry_or_junk(ps)
      entry_start_pos = ps.index

      begin
        entry = get_entry(ps)
        ps.expect_line_end
        entry
      rescue ParseError => err
        error_index = ps.index
        ps.skip_to_next_entry_start(entry_start_pos)
        next_entry_start = ps.index
        
        if next_entry_start < error_index
          # The position of the error must be inside of the Junk's span.
          error_index = next_entry_start
        end

        # Create a Junk instance
        slice = ps.string[entry_start_pos...next_entry_start]
        junk = Junk.new(slice)
        
        if @with_spans
          junk.add_span(entry_start_pos, next_entry_start)
        end
        
        annot = Annotation.new(err.code, err.args, err.message)
        if @with_spans
          annot.add_span(error_index, error_index)
        end
        junk.annotations << annot
        
        junk
      end
    end

    def get_entry(ps)
      case ps.current_char
      when "#"
        get_comment(ps)
      when "-"
        get_term(ps)
      else
        if ps.identifier_start?
          get_message(ps)
        else
          raise ParseError.new("E0002")
        end
      end
    end

    def get_comment(ps)
      # 0 - comment, 1 - group comment, 2 - resource comment
      level = -1
      content = ""

      loop do
        i = -1
        while ps.current_char == "#" && i < (level == -1 ? 2 : level)
          ps.next
          i += 1
        end

        level = i if level == -1

        if ps.current_char != Stream::EOL
          ps.expect_char(" ")
          ch = nil
          while (ch = ps.take_char { |x| x != Stream::EOL })
            content += ch
          end
        end

        if ps.next_line_comment?(level)
          content += ps.current_char
          ps.next
        else
          break
        end
      end

      comment_class = case level
                      when 0
                        Comment
                      when 1
                        GroupComment
                      else
                        ResourceComment
                      end
      
      result = comment_class.new(content)
      add_span_if_enabled(result, ps)
      result
    end

    def get_message(ps)
      start_pos = ps.index if @with_spans
      
      id = get_identifier(ps)
      ps.skip_blank_inline
      ps.expect_char("=")

      value = maybe_get_pattern(ps)
      attrs = get_attributes(ps)

      if value.nil? && attrs.empty?
        raise ParseError.new("E0005", id.name)
      end

      result = Message.new(id, value, attrs)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def get_term(ps)
      start_pos = ps.index if @with_spans
      
      ps.expect_char("-")
      id = get_identifier(ps)
      ps.skip_blank_inline
      ps.expect_char("=")

      value = maybe_get_pattern(ps)
      if value.nil?
        raise ParseError.new("E0006", id.name)
      end

      attrs = get_attributes(ps)
      result = Term.new(id, value, attrs)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def get_attribute(ps)
      start_pos = ps.index if @with_spans
      
      ps.expect_char(".")
      key = get_identifier(ps)
      ps.skip_blank_inline
      ps.expect_char("=")

      value = maybe_get_pattern(ps)
      if value.nil?
        raise ParseError.new("E0012")
      end

      result = Attribute.new(key, value)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def get_attributes(ps)
      attrs = []
      ps.peek_blank
      
      while ps.attribute_start?
        ps.skip_to_peek
        attr = get_attribute(ps)
        attrs << attr
        ps.peek_blank
      end
      
      attrs
    end

    def get_identifier(ps)
      start_pos = ps.index if @with_spans
      
      name = ps.take_id_start
      
      ch = nil
      while (ch = ps.take_id_char)
        name += ch
      end

      result = Identifier.new(name)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def get_variant_key(ps)
      ch = ps.current_char
      
      if ch == Stream::EOF
        raise ParseError.new("E0013")
      end

      cc = ch.ord
      if (cc >= 48 && cc <= 57) || cc == 45  # 0-9, -
        get_number(ps)
      else
        get_identifier(ps)
      end
    end

    def get_variant(ps, has_default = false)
      start_pos = ps.index if @with_spans
      default_index = false

      if ps.current_char == "*"
        if has_default
          raise ParseError.new("E0015")
        end
        ps.next
        default_index = true
      end

      ps.expect_char("[")
      ps.skip_blank
      key = get_variant_key(ps)
      ps.skip_blank
      ps.expect_char("]")

      value = maybe_get_pattern(ps)
      if value.nil?
        raise ParseError.new("E0012")
      end

      result = Variant.new(key, value, default_index)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def get_variants(ps)
      variants = []
      has_default = false

      ps.skip_blank
      while ps.variant_start?
        variant = get_variant(ps, has_default)
        has_default = true if variant.default
        variants << variant
        ps.expect_line_end
        ps.skip_blank
      end

      if variants.empty?
        raise ParseError.new("E0011")
      end

      unless has_default
        raise ParseError.new("E0010")
      end

      variants
    end

    def get_digits(ps)
      num = ""
      
      ch = nil
      while (ch = ps.take_digit)
        num += ch
      end

      if num.empty?
        raise ParseError.new("E0004", "0-9")
      end

      num
    end

    def get_number(ps)
      start_pos = ps.index if @with_spans
      value = ""

      if ps.current_char == "-"
        ps.next
        value += "-#{get_digits(ps)}"
      else
        value += get_digits(ps)
      end

      if ps.current_char == "."
        ps.next
        value += ".#{get_digits(ps)}"
      end

      result = NumberLiteral.new(value)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def maybe_get_pattern(ps)
      ps.peek_blank_inline
      if ps.value_start?
        ps.skip_to_peek
        return get_pattern(ps, false)
      end

      ps.peek_blank_block
      if ps.value_continuation?
        ps.skip_to_peek
        return get_pattern(ps, true)
      end

      nil
    end

    def get_pattern(ps, is_block)
      start_pos = ps.index if @with_spans
      elements = []
      common_indent_length = nil

      if is_block
        # A block pattern is a pattern which starts on a new line. Store and
        # measure the indent of this first line for the dedentation logic.
        blank_start = ps.index
        first_indent = ps.skip_blank_inline
        elements << get_indent(ps, first_indent, blank_start)
        common_indent_length = first_indent.length
      else
        common_indent_length = Float::INFINITY
      end

      loop do
        ch = ps.current_char
        break unless ch

        case ch
        when Stream::EOL
          blank_start = ps.index
          blank_lines = ps.peek_blank_block
          if ps.value_continuation?
            ps.skip_to_peek
            indent = ps.skip_blank_inline
            common_indent_length = [common_indent_length, indent.length].min
            elements << get_indent(ps, blank_lines + indent, blank_start)
            next
          end

          # The end condition for getPattern's while loop is a newline
          # which is not followed by a valid pattern continuation.
          ps.reset_peek
          break
        when "{"
          elements << get_placeable(ps)
          next
        when "}"
          raise ParseError.new("E0027")
        else
          elements << get_text_element(ps)
        end
      end

      dedented = dedent(elements, common_indent_length)
      result = Pattern.new(dedented)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    # Create a token representing an indent. It's not part of the AST and it will
    # be trimmed and merged into adjacent TextElements, or turned into a new
    # TextElement, if it's surrounded by two Placeables.
    def get_indent(ps, value, start)
      # Ruby doesn't need a separate Indent class - we'll use a simple struct
      indent_struct = Struct.new(:value, :start, :end, :span) do
        def is_a?(klass)
          klass == Indent || super
        end
        
        class << self
          def name
            "Indent"
          end
        end
      end
      
      indent = indent_struct.new(value, start, ps.index)
      if @with_spans
        span_struct = Struct.new(:start, :end)
        indent.span = span_struct.new(start, ps.index)
      end
      indent
    end

    # Dedent a list of elements by removing the maximum common indent from the
    # beginning of text lines. The common indent is calculated in get_pattern.
    def dedent(elements, common_indent)
      trimmed = []

      elements.each do |element|
        if element.is_a?(Placeable)
          trimmed << element
          next
        end

        if element.is_a?(Indent)
          # Strip common indent.
          element.value = element.value[0...(element.value.length - common_indent)]
          next if element.value.empty?
        end

        prev = trimmed.last
        if prev&.is_a?(TextElement)
          # Join adjacent TextElements by replacing them with their sum.
          sum = TextElement.new(prev.value + element.value)
          if @with_spans && prev.span && element.span
            sum.add_span(prev.span.start, element.span.end)
          end
          trimmed[-1] = sum
          next
        end

        if element.is_a?(Indent)
          # If the indent hasn't been merged into a preceding TextElement,
          # convert it into a new TextElement.
          text_element = TextElement.new(element.value)
          if @with_spans && element.span
            text_element.add_span(element.span.start, element.span.end)
          end
          element = text_element
        end

        trimmed << element
      end

      # Trim trailing whitespace from the Pattern.
      last_element = trimmed.last
      if last_element.is_a?(TextElement)
        last_element.value = last_element.value.gsub(TRAILING_WS_RE, "")
        trimmed.pop if last_element.value.empty?
      end

      trimmed
    end

    def get_text_element(ps)
      start_pos = ps.index if @with_spans
      buffer = ""

      loop do
        ch = ps.current_char
        break unless ch

        if ch == "{" || ch == "}"
          break
        end

        if ch == Stream::EOL
          break
        end

        buffer += ch
        ps.next
      end

      result = TextElement.new(buffer)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def get_placeable(ps)
      start_pos = ps.index if @with_spans
      
      ps.expect_char("{")
      ps.skip_blank
      expression = get_expression(ps)
      ps.expect_char("}")
      
      result = Placeable.new(expression)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    # Helper method to add spans consistently
    def add_span_if_enabled(node, ps, start_pos = nil)
      if @with_spans
        start_pos ||= ps.index
        node.add_span(start_pos, ps.index) unless node.span
      end
    end

    def get_expression(ps)
      start_pos = ps.index if @with_spans
      
      selector = get_inline_expression(ps)
      ps.skip_blank

      if ps.current_char == "-"
        if ps.peek != ">"
          ps.reset_peek
          return selector
        end

        # Validate selector expression according to
        # abstract.js in the Fluent specification
        if selector.is_a?(MessageReference)
          if selector.attribute.nil?
            raise ParseError.new("E0016")
          else
            raise ParseError.new("E0018")
          end
        elsif selector.is_a?(TermReference)
          if selector.attribute.nil?
            raise ParseError.new("E0017")
          end
        elsif selector.is_a?(Placeable)
          raise ParseError.new("E0029")
        end

        ps.next
        ps.next

        ps.skip_blank_inline
        ps.expect_line_end

        variants = get_variants(ps)
        result = SelectExpression.new(selector, variants)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      if selector.is_a?(TermReference) && !selector.attribute.nil?
        raise ParseError.new("E0019")
      end

      selector
    end

    def get_inline_expression(ps)
      start_pos = ps.index if @with_spans

      if ps.current_char == "{"
        return get_placeable(ps)
      end

      if ps.number_start?
        return get_number(ps)
      end

      if ps.current_char == '"'
        return get_string(ps)
      end

      if ps.current_char == "$"
        ps.next
        id = get_identifier(ps)
        result = VariableReference.new(id)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      if ps.current_char == "-"
        ps.next
        id = get_identifier(ps)

        attr = nil
        if ps.current_char == "."
          ps.next
          attr = get_identifier(ps)
        end

        args = nil
        ps.peek_blank
        if ps.current_peek == "("
          ps.skip_to_peek
          args = get_call_arguments(ps)
        end

        result = TermReference.new(id, attr, args)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      if ps.identifier_start?
        id = get_identifier(ps)
        ps.peek_blank

        if ps.current_peek == "("
          # It's a Function. Ensure it's all upper-case.
          unless /^[A-Z][A-Z0-9_-]*$/.match?(id.name)
            raise ParseError.new("E0008")
          end

          ps.skip_to_peek
          args = get_call_arguments(ps)
          result = FunctionReference.new(id, args)
          add_span_if_enabled(result, ps, start_pos)
          return result
        end

        attr = nil
        if ps.current_char == "."
          ps.next
          attr = get_identifier(ps)
        end

        result = MessageReference.new(id, attr)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      raise ParseError.new("E0028")
    end

    def get_call_argument(ps)
      start_pos = ps.index if @with_spans
      
      exp = get_inline_expression(ps)
      ps.skip_blank

      if ps.current_char != ":"
        return exp
      end

      if exp.is_a?(MessageReference) && exp.attribute.nil?
        ps.next
        ps.skip_blank

        value = get_literal(ps)
        result = NamedArgument.new(exp.id, value)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      raise ParseError.new("E0009")
    end

    def get_call_arguments(ps)
      start_pos = ps.index if @with_spans
      
      positional = []
      named = []
      argument_names = Set.new

      ps.expect_char("(")
      ps.skip_blank

      loop do
        break if ps.current_char == ")"

        arg = get_call_argument(ps)
        if arg.is_a?(NamedArgument)
          if argument_names.include?(arg.name.name)
            raise ParseError.new("E0022")
          end
          named << arg
          argument_names.add(arg.name.name)
        elsif !argument_names.empty?
          raise ParseError.new("E0021")
        else
          positional << arg
        end

        ps.skip_blank

        if ps.current_char == ","
          ps.next
          ps.skip_blank
          next
        end

        break
      end

      ps.expect_char(")")
      result = CallArguments.new(positional, named)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def get_string(ps)
      start_pos = ps.index if @with_spans
      
      ps.expect_char('"')
      value = ""

      ch = nil
      while (ch = ps.take_char { |x| x != '"' && x != Stream::EOL })
        if ch == "\\"
          value += get_escape_sequence(ps)
        else
          value += ch
        end
      end

      if ps.current_char == Stream::EOL
        raise ParseError.new("E0020")
      end

      ps.expect_char('"')
      
      result = StringLiteral.new(value)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    def get_escape_sequence(ps)
      next_char = ps.current_char

      case next_char
      when "\\", '"'
        ps.next
        "\\#{next_char}"
      when "u"
        get_unicode_escape_sequence(ps, next_char, 4)
      when "U"
        get_unicode_escape_sequence(ps, next_char, 6)
      else
        raise ParseError.new("E0025", next_char)
      end
    end

    def get_unicode_escape_sequence(ps, u, digits)
      ps.expect_char(u)

      sequence = ""
      digits.times do
        ch = ps.take_hex_digit
        
        unless ch
          raise ParseError.new("E0026", "\\#{u}#{sequence}#{ps.current_char}")
        end

        sequence += ch
      end

      "\\#{u}#{sequence}"
    end

    def get_literal(ps)
      if ps.number_start?
        return get_number(ps)
      end

      if ps.current_char == '"'
        return get_string(ps)
      end

      raise ParseError.new("E0014")
    end

    # Define Indent as a constant for type checking
    Indent = Class.new do
      def self.name
        "Indent"
      end
    end
  end
end