# frozen_string_literal: true

module Foxtail
  # Serializes AST nodes back to FTL format
  class Serializer
    # Create a new Serializer instance
    # @param with_junk [Boolean] Whether to include junk entries in output (default: false)
    def initialize(with_junk: false)
      @with_junk = with_junk
    end

    # @return [Boolean] Whether to include junk entries in output
    def with_junk? = @with_junk

    # Serialize a Resource AST to FTL string
    # @return [String] FTL formatted source text
    def serialize(resource)
      has_entries = false
      parts = []

      resource.body.each do |entry|
        next if entry.is_a?(Parser::AST::Junk) && !with_junk?

        parts << serialize_entry(entry, has_entries:)
        has_entries = true
      end

      parts.join
    end

    # Serialize a single entry (Message, Term, Comment, or Junk)
    # @return [String] FTL formatted entry text
    def serialize_entry(entry, has_entries: false)
      case entry
      when Parser::AST::Message
        serialize_message(entry)
      when Parser::AST::Term
        serialize_term(entry)
      when Parser::AST::Comment
        serialize_standalone_comment(entry, "#", has_entries)
      when Parser::AST::GroupComment
        serialize_standalone_comment(entry, "##", has_entries)
      when Parser::AST::ResourceComment
        serialize_standalone_comment(entry, "###", has_entries)
      when Parser::AST::Junk
        serialize_junk(entry)
      else
        raise ArgumentError, "Unknown entry type: #{entry.class}"
      end
    end

    private def serialize_standalone_comment(comment, prefix, has_entries)
      result = serialize_comment(comment, prefix)
      if has_entries
        "\n#{result}\n"
      else
        "#{result}\n"
      end
    end

    private def serialize_comment(comment, prefix="#")
      prefixed = comment.content.split("\n").map {|line|
        line.empty? ? prefix : "#{prefix} #{line}"
      }.join("\n")
      "#{prefixed}\n"
    end

    private def serialize_junk(junk) = junk.content

    private def serialize_message(message)
      parts = []
      parts << serialize_comment(message.comment) if message.comment
      parts << "#{message.id.name} ="
      parts << serialize_pattern(message.value) if message.value
      message.attributes.each {|attr| parts << serialize_attribute(attr) }
      parts << "\n"
      parts.join
    end

    private def serialize_term(term)
      parts = []
      parts << serialize_comment(term.comment) if term.comment
      parts << "-#{term.id.name} ="
      parts << serialize_pattern(term.value)
      term.attributes.each {|attr| parts << serialize_attribute(attr) }
      parts << "\n"
      parts.join
    end

    private def serialize_attribute(attribute)
      value = indent_except_first_line(serialize_pattern(attribute.value))
      "\n    .#{attribute.id.name} =#{value}"
    end

    private def serialize_pattern(pattern)
      content = pattern.elements.map {|elem| serialize_element(elem) }.join

      if should_start_on_new_line?(pattern)
        "\n    #{indent_except_first_line(content)}"
      else
        " #{indent_except_first_line(content)}"
      end
    end

    private def serialize_element(element)
      case element
      when Parser::AST::TextElement
        element.value
      when Parser::AST::Placeable
        serialize_placeable(element)
      else
        raise ArgumentError, "Unknown element type: #{element.class}"
      end
    end

    private def serialize_placeable(placeable)
      expr = placeable.expression
      case expr
      when Parser::AST::Placeable
        "{#{serialize_placeable(expr)}}"
      when Parser::AST::SelectExpression
        "{ #{serialize_expression(expr)}}"
      else
        "{ #{serialize_expression(expr)} }"
      end
    end

    private def serialize_expression(expr)
      case expr
      when Parser::AST::StringLiteral
        "\"#{expr.value}\""
      when Parser::AST::NumberLiteral
        expr.value
      when Parser::AST::VariableReference
        "$#{expr.id.name}"
      when Parser::AST::TermReference
        serialize_term_reference(expr)
      when Parser::AST::MessageReference
        serialize_message_reference(expr)
      when Parser::AST::FunctionReference
        "#{expr.id.name}#{serialize_call_arguments(expr.arguments)}"
      when Parser::AST::SelectExpression
        serialize_select_expression(expr)
      when Parser::AST::Placeable
        serialize_placeable(expr)
      else
        raise ArgumentError, "Unknown expression type: #{expr.class}"
      end
    end

    private def serialize_term_reference(ref)
      out = "-#{ref.id.name}"
      out += ".#{ref.attribute.name}" if ref.attribute
      out += serialize_call_arguments(ref.arguments) if ref.arguments
      out
    end

    private def serialize_message_reference(ref)
      out = ref.id.name
      out += ".#{ref.attribute.name}" if ref.attribute
      out
    end

    private def serialize_select_expression(expr)
      out = "#{serialize_expression(expr.selector)} ->"
      expr.variants.each {|variant| out += serialize_variant(variant) }
      "#{out}\n"
    end

    private def serialize_variant(variant)
      key = serialize_variant_key(variant.key)
      value = indent_except_first_line(serialize_pattern(variant.value))

      if variant.default
        "\n   *[#{key}]#{value}"
      else
        "\n    [#{key}]#{value}"
      end
    end

    private def serialize_variant_key(key)
      case key
      when Parser::AST::Identifier
        key.name
      when Parser::AST::NumberLiteral
        key.value
      else
        raise ArgumentError, "Unknown variant key type: #{key.class}"
      end
    end

    private def serialize_call_arguments(args)
      return "()" if args.nil?

      positional = args.positional.map {|arg| serialize_expression(arg) }.join(", ")
      named = args.named.map {|arg| serialize_named_argument(arg) }.join(", ")

      if !positional.empty? && !named.empty?
        "(#{positional}, #{named})"
      else
        "(#{positional}#{named})"
      end
    end

    private def serialize_named_argument(arg)
      value = serialize_expression(arg.value)
      "#{arg.name.name}: #{value}"
    end

    private def indent_except_first_line(content)
      content.split("\n").join("\n    ")
    end

    private def should_start_on_new_line?(pattern)
      is_multiline = pattern.elements.any? {|elem|
        select_expr?(elem) || includes_newline?(elem)
      }

      return false unless is_multiline

      first_element = pattern.elements.first
      return true unless first_element.is_a?(Parser::AST::TextElement)

      first_char = first_element.value[0]
      # These characters may not appear as the first character on a new line
      !["[", ".", "*"].include?(first_char)
    end

    private def select_expr?(elem)
      elem.is_a?(Parser::AST::Placeable) && elem.expression.is_a?(Parser::AST::SelectExpression)
    end

    private def includes_newline?(elem)
      elem.is_a?(Parser::AST::TextElement) && elem.value.include?("\n")
    end
  end
end
