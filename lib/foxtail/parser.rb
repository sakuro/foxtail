# frozen_string_literal: true

require_relative "ast/base"
require_relative "ast/expression"
require_relative "ast/message"
require_relative "ast/pattern"
require_relative "ast/resource"
require_relative "errors"
require_relative "stream"

module Foxtail
  # Parser for FTL (Fluent Translation List) files
  class Parser
    attr_reader :with_spans

    def initialize(with_spans: true)
      @with_spans = with_spans
    end

    # Parse FTL source into an AST::Resource
    #
    # @param source [String] FTL source to parse
    # @return [AST::Resource] Parsed resource
    def parse(source)
      ps = FluentParserStream.new(source)
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
        if entry.is_a?(AST::Comment) && blank_lines.empty? && ps.current_char
          # Stash the comment and decide what to do with it in the next pass.
          last_comment = entry
          next
        end

        if last_comment
          if entry.is_a?(AST::Message) || entry.is_a?(AST::Term)
            entry.comment = last_comment
            if @with_spans && entry.span && last_comment.span
              entry.span.start_pos = last_comment.span.start_pos
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

      resource = AST::Resource.new(entries)
      resource.add_span(0, ps.index) if @with_spans
      resource
    end

    private def get_entry_or_junk(ps)
      entry_start_pos = ps.index

      begin
        entry = get_entry(ps)
        ps.expect_line_end
        add_span(entry, entry_start_pos, ps.index)
        entry
      rescue Errors::ParseError => e
        error_index = ps.index
        ps.skip_to_next_entry_start(entry_start_pos)
        next_entry_start = ps.index

        if next_entry_start < error_index
          error_index = next_entry_start
        end

        # Create a Junk instance
        slice = ps.string[entry_start_pos...next_entry_start]
        junk = AST::Junk.new(slice)
        add_span(junk, entry_start_pos, next_entry_start)

        annotation = AST::Annotation.new(e.code, e.args, e.message)
        add_span(annotation, error_index, error_index)
        junk.add_annotation(annotation)
        junk
      end
    end

    private def get_entry(ps)
      if ps.current_char == "#"
        return get_comment(ps)
      end

      if ps.current_char == "-"
        return get_term(ps)
      end

      if ps.char_id_start?(ps.current_char)
        return get_message(ps)
      end

      raise Errors::ParseError, "E0002"
    end

    private def get_comment(ps)
      # 0 - comment
      # 1 - group comment
      # 2 - resource comment
      level = -1
      content = ""

      comment_start = ps.index

      loop do
        i = -1
        while ps.current_char == "#" && i < (level == -1 ? 2 : level)
          ps.next_char
          i += 1
        end

        if level == -1
          level = i
        end

        if ps.current_char != EOL
          ps.expect_char(" ")
          content_start = ps.index
          while ps.take_char ->(x) { x != EOL }
            # Accumulate characters
          end
          content += ps.string[content_start...ps.index]
        end

        break unless ps.next_line_comment?(level)

        content += ps.current_char
        ps.next_char
      end

      # Create a comment class based on the comment level
      comment =
        case level
        when 0
          AST::Comment.new(content)
        when 1
          AST::GroupComment.new(content)
        when 2
          AST::ResourceComment.new(content)
        else
          # Treat unknown levels as regular comments
          AST::Comment.new(content)
        end

      add_span(comment, comment_start, ps.index)
      comment
    end

    private def get_message(ps)
      message_start = ps.index

      id = get_identifier(ps)

      ps.skip_blank_inline
      ps.expect_char("=")

      value = maybe_get_pattern(ps)
      attrs = get_attributes(ps)

      if value.nil? && attrs.empty?
        raise Errors::ParseError.new("E0005", id.name)
      end

      message = AST::Message.new(id, value, attrs)
      add_span(message, message_start, ps.index)
      message
    end

    private def get_term(ps)
      term_start = ps.index

      ps.expect_char("-")
      id = get_identifier(ps)

      ps.skip_blank_inline
      ps.expect_char("=")

      value = maybe_get_pattern(ps)
      if value.nil?
        raise Errors::ParseError.new("E0006", id.name)
      end

      attrs = get_attributes(ps)
      term = AST::Term.new(id, value, attrs)
      add_span(term, term_start, ps.index)
      term
    end

    private def get_attribute(ps)
      attr_start = ps.index

      ps.expect_char(".")

      key = get_identifier(ps)

      ps.skip_blank_inline
      ps.expect_char("=")

      value = maybe_get_pattern(ps)
      if value.nil?
        raise Errors::ParseError, "E0012"
      end

      attr = AST::Attribute.new(key, value)
      add_span(attr, attr_start, ps.index)
      attr
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
      id_start = ps.index

      name = ps.take_id_start
      while (ch = ps.take_id_char)
        name += ch
      end

      id = AST::Identifier.new(name)
      add_span(id, id_start, ps.index)
      id
    end

    private def get_variant_key(ps)
      ps.index

      ch = ps.current_char

      if ch == EOF
        raise Errors::ParseError, "E0013"
      end

      if /[0-9-]/.match?(ch)
        return get_number(ps)
      end

      get_identifier(ps)
    end

    private def get_variant(ps, has_default: false)
      variant_start = ps.index

      default_index = false

      if ps.current_char == "*"
        if has_default
          raise Errors::ParseError, "E0015"
        end

        ps.next_char
        default_index = true
      end

      ps.expect_char("[")

      ps.skip_blank

      key = get_variant_key(ps)

      ps.skip_blank
      ps.expect_char("]")

      value = maybe_get_pattern(ps)
      if value.nil?
        raise Errors::ParseError, "E0012"
      end

      variant = AST::Variant.new(key, value, default: default_index)
      add_span(variant, variant_start, ps.index)
      variant
    end

    private def get_variants(ps)
      variants = []
      has_default = false

      ps.skip_blank
      while ps.variant_start?
        variant = get_variant(ps, has_default:)

        if variant.default
          has_default = true
        end

        variants << variant
        ps.expect_line_end
        ps.skip_blank
      end

      if variants.empty?
        raise Errors::ParseError, "E0011"
      end

      unless has_default
        raise Errors::ParseError, "E0010"
      end

      variants
    end

    private def get_digits(ps)
      ps.index

      num = ""
      while (ch = ps.take_digit)
        num += ch
      end

      if num.empty?
        raise Errors::ParseError.new("E0004", "0-9")
      end

      num
    end

    private def get_number(ps)
      number_start = ps.index

      value = ""

      if ps.current_char == "-"
        ps.next_char
        value += "-#{get_digits(ps)}"
      else
        value += get_digits(ps)
      end

      if ps.current_char == "."
        ps.next_char
        value += ".#{get_digits(ps)}"
      end

      number = AST::NumberLiteral.new(value)
      add_span(number, number_start, ps.index)
      number
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
      pattern_start = ps.index

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

      ch = nil
      loop do
        ch = ps.current_char
        break if ch == EOF

        case ch
        when EOL
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
          raise Errors::ParseError, "E0027"
        else
          elements << get_text_element(ps)
        end
      end

      dedented = dedent(elements, common_indent_length)
      pattern = AST::Pattern.new(dedented)
      add_span(pattern, pattern_start, ps.index)
      pattern
    end

    private def get_indent(ps, value, start)
      Indent.new(value, start, ps.index)
    end

    private def dedent(elements, common_indent)
      trimmed = []

      elements.each do |element|
        if element.is_a?(AST::Placeable)
          trimmed << element
          next
        end

        if element.is_a?(Indent)
          # Strip common indent.
          element.value = element.value[0...-common_indent]
          if element.value.empty?
            next
          end
        end

        prev = trimmed.last
        if prev.is_a?(AST::TextElement)
          # Join adjacent TextElements by replacing them with their sum.
          sum = AST::TextElement.new(prev.value + element.value)
          if @with_spans && prev.span && element.span
            sum.add_span(prev.span.start_pos, element.span.end_pos)
          end
          trimmed[-1] = sum
          next
        end

        if element.is_a?(Indent)
          # If the indent hasn't been merged into a preceding TextElement,
          # convert it into a new TextElement.
          text_element = AST::TextElement.new(element.value)
          if @with_spans && element.span
            text_element.add_span(element.span.start_pos, element.span.end_pos)
          end
          element = text_element
        end

        trimmed << element
      end

      # Trim trailing whitespace from the Pattern.
      last_element = trimmed.last
      if last_element.is_a?(AST::TextElement)
        trimmed_value = last_element.value.sub(/[ \n\r]+$/, "")
        if trimmed_value.empty?
          trimmed.pop
        else
          # Create a new TextElement to replace the old one
          new_element = AST::TextElement.new(trimmed_value)
          if @with_spans && last_element.span
            new_element.add_span(last_element.span.start_pos, last_element.span.end_pos)
          end
          trimmed[-1] = new_element
        end
      end

      trimmed
    end

    private def get_text_element(ps)
      text_start = ps.index

      buffer = ""
      while (ch = ps.current_char)
        if ch == "{" || ch == "}" || ch == EOL || ch == EOF
          break
        end

        buffer += ch
        ps.next_char
      end

      text_element = AST::TextElement.new(buffer)
      add_span(text_element, text_start, ps.index)
      text_element
    end

    private def get_escape_sequence(ps)
      ps.index

      next_char = ps.current_char

      case next_char
      when "\\", '"'
        ps.next_char
        "\\#{next_char}"
      when "u"
        get_unicode_escape_sequence(ps, next_char, 4)
      when "U"
        get_unicode_escape_sequence(ps, next_char, 6)
      else
        raise Errors::ParseError.new("E0025", next_char)
      end
    end

    private def get_unicode_escape_sequence(ps, u, digits)
      ps.index

      ps.expect_char(u)

      sequence = ""
      digits.times do
        ch = ps.take_hex_digit

        unless ch
          raise Errors::ParseError.new("E0026", "\\#{u}#{sequence}#{ps.current_char}")
        end

        sequence += ch
      end

      "\\#{u}#{sequence}"
    end

    private def get_placeable(ps)
      placeable_start = ps.index

      ps.expect_char("{")
      ps.skip_blank
      expression = get_expression(ps)
      ps.expect_char("}")

      placeable = AST::Placeable.new(expression)
      add_span(placeable, placeable_start, ps.index)
      placeable
    end

    private def get_expression(ps)
      expression_start = ps.index

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
          raise Errors::ParseError, "E0016" if selector.attribute.nil?

          raise Errors::ParseError, "E0018"

        when AST::TermReference
          if selector.attribute.nil?
            raise Errors::ParseError, "E0017"
          end
        when AST::Placeable
          raise Errors::ParseError, "E0029"
        else
          # TODO: Need to investigate what conditions can reach here
        end

        ps.next_char
        ps.next_char

        ps.skip_blank_inline
        ps.expect_line_end

        variants = get_variants(ps)
        select_expr = AST::SelectExpression.new(selector, variants)
        add_span(select_expr, expression_start, ps.index)
        return select_expr
      end

      if selector.is_a?(AST::TermReference) && !selector.attribute.nil?
        raise Errors::ParseError, "E0019"
      end

      selector
    end

    private def get_inline_expression(ps)
      expression_start = ps.index

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
        ps.next_char
        id = get_identifier(ps)
        var_ref = AST::VariableReference.new(id)
        add_span(var_ref, expression_start, ps.index)
        return var_ref
      end

      if ps.current_char == "-"
        ps.next_char
        id = get_identifier(ps)

        attr = nil
        if ps.current_char == "."
          ps.next_char
          attr = get_identifier(ps)
        end

        args = nil
        ps.peek_blank
        if ps.current_peek == "("
          ps.skip_to_peek
          args = get_call_arguments(ps)
        end

        term_ref = AST::TermReference.new(id, attr, args)
        add_span(term_ref, expression_start, ps.index)
        return term_ref
      end

      if ps.char_id_start?(ps.current_char)
        id = get_identifier(ps)
        ps.peek_blank

        if ps.current_peek == "("
          # It's a Function. Ensure it's all upper-case.
          unless /^[A-Z][A-Z0-9_-]*$/.match?(id.name)
            raise Errors::ParseError, "E0008"
          end

          ps.skip_to_peek
          args = get_call_arguments(ps)
          func_ref = AST::FunctionReference.new(id, args)
          add_span(func_ref, expression_start, ps.index)
          return func_ref
        end

        attr = nil
        if ps.current_char == "."
          ps.next_char
          attr = get_identifier(ps)
        end

        msg_ref = AST::MessageReference.new(id, attr)
        add_span(msg_ref, expression_start, ps.index)
        return msg_ref
      end

      raise Errors::ParseError, "E0028"
    end

    private def get_call_argument(ps)
      arg_start = ps.index

      exp = get_inline_expression(ps)

      ps.skip_blank

      if ps.current_char != ":"
        return exp
      end

      if exp.is_a?(AST::MessageReference) && exp.attribute.nil?
        ps.next_char
        ps.skip_blank

        value = get_literal(ps)
        named_arg = AST::NamedArgument.new(exp.id, value)
        add_span(named_arg, arg_start, ps.index)
        return named_arg
      end

      raise Errors::ParseError, "E0009"
    end

    private def get_call_arguments(ps)
      args_start = ps.index

      positional = []
      named = []
      argument_names = Set.new

      ps.expect_char("(")
      ps.skip_blank

      loop do
        if ps.current_char == ")"
          break
        end

        arg = get_call_argument(ps)
        if arg.is_a?(AST::NamedArgument)
          if argument_names.include?(arg.name.name)
            raise Errors::ParseError, "E0022"
          end

          named << arg
          argument_names.add(arg.name.name)
        elsif !argument_names.empty?
          raise Errors::ParseError, "E0021"
        else
          positional << arg
        end

        ps.skip_blank

        if ps.current_char == ","
          ps.next_char
          ps.skip_blank
          next
        end

        break
      end

      ps.expect_char(")")
      call_args = AST::CallArguments.new(positional, named)
      add_span(call_args, args_start, ps.index)
      call_args
    end

    private def get_string(ps)
      string_start = ps.index

      ps.expect_char('"')
      value = ""
      while (ch = ps.take_char ->(x) { x != '"' && x != EOL })
        value += if ch == "\\"
                   get_escape_sequence(ps)
                 else
                   ch
                 end
      end

      if ps.current_char == EOL
        raise Errors::ParseError, "E0020"
      end

      ps.expect_char('"')

      string = AST::StringLiteral.new(value)
      add_span(string, string_start, ps.index)
      string
    end

    private def get_literal(ps)
      if ps.number_start?
        return get_number(ps)
      end

      if ps.current_char == '"'
        return get_string(ps)
      end

      raise Errors::ParseError, "E0014"
    end

    private def add_span(node, start, end_pos)
      node.add_span(start, end_pos) if @with_spans
      node
    end
  end

  # Indent class for pattern dedentation
  class Indent
    attr_accessor :value
    attr_accessor :span

    def initialize(value, start, end_pos)
      @value = value
      @span = AST::Span.new(start, end_pos)
    end
  end
end
