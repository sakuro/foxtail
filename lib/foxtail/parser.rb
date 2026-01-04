# frozen_string_literal: true

module Foxtail
  # Ruby equivalent of fluent.js FluentParser
  # Translates TypeScript parsing logic to Ruby
  class Parser
    TRAILING_WS_RE = /[ \n\r]+\z/
    private_constant :TRAILING_WS_RE

    # Define Indent as a Struct for temporary indentation tokens
    # Note: Uses Struct instead of Data.define because the value field is mutated in dedent()
    Indent = Struct.new(:value, :start, :end, :span, keyword_init: true)

    # Create a new Parser instance
    # @param with_spans [Boolean] Whether to include span information in AST nodes (default: true)
    def initialize(with_spans: true)
      @with_spans = with_spans
    end

    # @return [Boolean] Whether to include span information in AST nodes
    def with_spans? = @with_spans

    # Main entry point - parse FTL source into AST
    # @param source [String] FTL source text to parse
    # @return [Parser::AST::Resource]
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
        # they should parse as standalone when they're followed by AST::Junk.
        # Consequently, we only attach Comments once we know that the AST::Message
        # or the AST::Term parsed successfully.
        if entry.is_a?(AST::Comment) && blank_lines.length == 0 && ps.current_char
          # Stash the comment and decide what to do with it in the next pass.
          last_comment = entry
          next
        end

        if last_comment
          if entry.is_a?(AST::Message) || entry.is_a?(AST::Term)
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

      res = AST::Resource.new(entries)
      if @with_spans
        res.add_span(0, ps.index)
      end

      res
    end

    # Parse the first AST::Message or AST::Term in source
    # @param source [String] FTL source text to parse
    # @return [Parser::AST::Message, Parser::AST::Term, Parser::AST::Junk]
    def parse_entry(source)
      ps = Stream.new(source)
      ps.skip_blank_block

      while ps.current_char == "#"
        skipped = get_entry_or_junk(ps)
        return skipped if skipped.is_a?(AST::Junk)

        ps.skip_blank_block
      end

      get_entry_or_junk(ps)
    end

    private def get_entry_or_junk(ps)
      entry_start_pos = ps.index

      begin
        entry = get_entry(ps)
        ps.expect_line_end
        entry
      rescue ParseError => e
        error_index = ps.index
        ps.skip_to_next_entry_start(entry_start_pos)
        next_entry_start = ps.index

        if next_entry_start < error_index
          # The position of the error must be inside of the Junk's span.
          error_index = next_entry_start
        end

        # Create a AST::Junk instance
        slice = ps.string[entry_start_pos...next_entry_start]
        junk = AST::Junk.new(slice)

        if @with_spans
          junk.add_span(entry_start_pos, next_entry_start)
        end

        annot = AST::Annotation.new(e.code, e.args, e.message)
        if @with_spans
          annot.add_span(error_index, error_index)
        end
        junk.annotations << annot

        junk
      end
    end

    private def get_entry(ps)
      case ps.current_char
      when "#"
        get_comment(ps)
      when "-"
        get_term(ps)
      else
        raise ParseError, "E0002" unless ps.identifier_start?

        get_message(ps)
      end
    end

    private def get_comment(ps)
      start_pos = ps.index if @with_spans

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
          while (ch = ps.take_char {|x| x != Stream::EOL })
            content += ch
          end
        end

        break unless ps.next_line_comment?(level)

        content += ps.current_char
        ps.next
      end

      result = comment_class_for_level(level).new(content)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def comment_class_for_level(level)
      case level
      when 0 then AST::Comment
      when 1 then AST::GroupComment
      else AST::ResourceComment
      end
    end

    private def get_message(ps)
      start_pos = ps.index if @with_spans

      id = get_identifier(ps)
      ps.skip_blank_inline
      ps.expect_char("=")

      value = maybe_get_pattern(ps)
      attrs = get_attributes(ps)

      if value.nil? && attrs.empty?
        raise ParseError.new("E0005", id.name)
      end

      result = AST::Message.new(id, value, attrs)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def get_term(ps)
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
      result = AST::Term.new(id, value, attrs)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def get_attribute(ps)
      start_pos = ps.index if @with_spans

      ps.expect_char(".")
      key = get_identifier(ps)
      ps.skip_blank_inline
      ps.expect_char("=")

      value = maybe_get_pattern(ps)
      if value.nil?
        raise ParseError, "E0012"
      end

      result = AST::Attribute.new(key, value)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def get_attributes(ps)
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

    private def get_identifier(ps)
      start_pos = ps.index if @with_spans

      name = ps.take_id_start

      while (ch = ps.take_id_char)
        name += ch
      end

      result = AST::Identifier.new(name)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def get_variant_key(ps)
      ch = ps.current_char

      if ch == Stream::EOF
        raise ParseError, "E0013"
      end

      cc = ch.ord
      if cc.between?(48, 57) || cc == 45 # 0-9, -
        get_number(ps)
      else
        get_identifier(ps)
      end
    end

    private def get_variant(ps, has_default: false)
      start_pos = ps.index if @with_spans
      default_index = false

      if ps.current_char == "*"
        if has_default
          raise ParseError, "E0015"
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
        raise ParseError, "E0012"
      end

      result = AST::Variant.new(key, value, default: default_index)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def get_variants(ps)
      variants = []
      has_default = false

      ps.skip_blank
      while ps.variant_start?
        variant = get_variant(ps, has_default:)
        has_default = true if variant.default
        variants << variant
        ps.expect_line_end
        ps.skip_blank
      end

      if variants.empty?
        raise ParseError, "E0011"
      end

      unless has_default
        raise ParseError, "E0010"
      end

      variants
    end

    private def get_digits(ps)
      num = ""

      while (ch = ps.take_digit)
        num += ch
      end

      if num.empty?
        raise ParseError.new("E0004", "0-9")
      end

      num
    end

    private def get_number(ps)
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

      result = AST::NumberLiteral.new(value)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def maybe_get_pattern(ps)
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

    private def get_pattern(ps, is_block)
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
          raise ParseError, "E0027"
        else
          elements << get_text_element(ps)
        end
      end

      dedented = dedent(elements, common_indent_length)
      result = AST::Pattern.new(dedented)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    # Create a token representing an indent. It's not part of the AST and it will
    # be trimmed and merged into adjacent TextElements, or turned into a new
    # AST::TextElement, if it's surrounded by two Placeables.
    private def get_indent(ps, value, start)
      span = @with_spans ? AST::Span.new(start, ps.index) : nil
      Indent.new(value:, start:, end: ps.index, span:)
    end

    # Dedent a list of elements by removing the maximum common indent from the
    # beginning of text lines. The common indent is calculated in get_pattern.
    private def dedent(elements, common_indent)
      trimmed = []

      elements.each do |element|
        if element.is_a?(AST::Placeable)
          trimmed << element
          next
        end

        if element.is_a?(Indent)
          # Strip common indent.
          element.value = element.value[0...(element.value.length - common_indent)]
          next if element.value.empty?
        end

        prev = trimmed.last
        if prev.is_a?(AST::TextElement)
          # Join adjacent TextElements by replacing them with their sum.
          sum = AST::TextElement.new(prev.value + element.value)
          if @with_spans && prev.span && element.span
            sum.add_span(prev.span.start, element.span.end)
          end
          trimmed[-1] = sum
          next
        end

        if element.is_a?(Indent)
          # If the indent hasn't been merged into a preceding AST::TextElement,
          # convert it into a new AST::TextElement.
          text_element = AST::TextElement.new(element.value)
          if @with_spans && element.span
            text_element.add_span(element.span.start, element.span.end)
          end
          element = text_element
        end

        trimmed << element
      end

      # Trim trailing whitespace from the AST::Pattern.
      last_element = trimmed.last
      if last_element.is_a?(AST::TextElement)
        last_element.value = last_element.value.gsub(TRAILING_WS_RE, "")
        trimmed.pop if last_element.value.empty?
      end

      trimmed
    end

    private def get_text_element(ps)
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

      result = AST::TextElement.new(buffer)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def get_placeable(ps)
      start_pos = ps.index if @with_spans

      ps.expect_char("{")
      ps.skip_blank
      expression = get_expression(ps)
      ps.expect_char("}")

      result = AST::Placeable.new(expression)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    # Helper method to add spans consistently
    private def add_span_if_enabled(node, ps, start_pos=nil)
      return unless @with_spans

      start_pos ||= ps.index
      node.add_span(start_pos, ps.index) unless node.span
    end

    private def get_expression(ps)
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
        case selector
        when AST::MessageReference
          raise ParseError, "E0016" if selector.attribute.nil?

          raise ParseError, "E0018"
        when AST::TermReference
          if selector.attribute.nil?
            raise ParseError, "E0017"
          end
        when AST::Placeable
          raise ParseError, "E0029"
        end

        ps.next
        ps.next

        ps.skip_blank_inline
        ps.expect_line_end

        variants = get_variants(ps)
        result = AST::SelectExpression.new(selector, variants)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      if selector.is_a?(AST::TermReference) && !selector.attribute.nil?
        raise ParseError, "E0019"
      end

      selector
    end

    private def get_inline_expression(ps)
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
        result = AST::VariableReference.new(id)
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

        result = AST::TermReference.new(id, attr, args)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      if ps.identifier_start?
        id = get_identifier(ps)
        ps.peek_blank

        if ps.current_peek == "("
          # It's a Function. Ensure it's all upper-case.
          unless /^[A-Z][A-Z0-9_-]*$/.match?(id.name)
            raise ParseError, "E0008"
          end

          ps.skip_to_peek
          args = get_call_arguments(ps)
          result = AST::FunctionReference.new(id, args)
          add_span_if_enabled(result, ps, start_pos)
          return result
        end

        attr = nil
        if ps.current_char == "."
          ps.next
          attr = get_identifier(ps)
        end

        result = AST::MessageReference.new(id, attr)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      raise ParseError, "E0028"
    end

    private def get_call_argument(ps)
      start_pos = ps.index if @with_spans

      exp = get_inline_expression(ps)
      ps.skip_blank

      if ps.current_char != ":"
        return exp
      end

      if exp.is_a?(AST::MessageReference) && exp.attribute.nil?
        ps.next
        ps.skip_blank

        value = get_literal(ps)
        result = AST::NamedArgument.new(exp.id, value)
        add_span_if_enabled(result, ps, start_pos)
        return result
      end

      raise ParseError, "E0009"
    end

    private def get_call_arguments(ps)
      start_pos = ps.index if @with_spans

      positional = []
      named = []
      argument_names = Set.new

      ps.expect_char("(")
      ps.skip_blank

      loop do
        break if ps.current_char == ")"

        arg = get_call_argument(ps)
        if arg.is_a?(AST::NamedArgument)
          if argument_names.include?(arg.name.name)
            raise ParseError, "E0022"
          end

          named << arg
          argument_names.add(arg.name.name)
        elsif !argument_names.empty?
          raise ParseError, "E0021"
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
      result = AST::CallArguments.new(positional, named)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def get_string(ps)
      start_pos = ps.index if @with_spans

      ps.expect_char('"')
      value = ""

      while (ch = ps.take_char {|x| x != '"' && x != Stream::EOL })
        value += ch == "\\" ? get_escape_sequence(ps) : ch
      end

      if ps.current_char == Stream::EOL
        raise ParseError, "E0020"
      end

      ps.expect_char('"')

      result = AST::StringLiteral.new(value)
      add_span_if_enabled(result, ps, start_pos)
      result
    end

    private def get_escape_sequence(ps)
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

    private def get_unicode_escape_sequence(ps, unicode_marker, digits)
      ps.expect_char(unicode_marker)

      sequence = ""
      digits.times do
        ch = ps.take_hex_digit

        unless ch
          raise ParseError.new("E0026", "\\#{unicode_marker}#{sequence}#{ps.current_char}")
        end

        sequence += ch
      end

      "\\#{unicode_marker}#{sequence}"
    end

    private def get_literal(ps)
      if ps.number_start?
        return get_number(ps)
      end

      if ps.current_char == '"'
        return get_string(ps)
      end

      raise ParseError, "E0014"
    end
  end
end
