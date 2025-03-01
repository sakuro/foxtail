# frozen_string_literal: true

require "parslet"

module Foxtail
  class Parser < Parslet::Parser
    # Basic rules
    rule(:space)      { match('\s').repeat(1) }
    rule(:space?)     { space.maybe }
    rule(:eol)        { str("\n") | str("\r\n") }
    rule(:line_end)   { eol | any.absent? }

    # Comment
    rule(:comment) do
      (str("#") >> match('[^\n]').repeat).as(:comment) >> line_end
    end

    # Identifier
    rule(:identifier) do
      match("[a-zA-Z]") >> match("[a-zA-Z0-9_-]").repeat
    end

    # Message
    rule(:message) do
      identifier.as(:id) >> space? >> str("=") >> space? >>
        pattern.as(:value) >>
        attribute.repeat.as(:attributes) >> line_end
    end

    # Pattern
    rule(:pattern) do
      (text_element | placeable).repeat(1).as(:pattern)
    end

    # Text element
    rule(:text_element) do
      match('[^{}\n]').repeat(1).as(:text)
    end

    # Placeable
    rule(:placeable) do
      str("{") >> space? >>
        (select_expression | inline_expression).as(:expression) >>
        space? >> str("}")
    end

    # Inline expression
    rule(:inline_expression) do
      variable_reference | message_reference | term_reference | function_call
    end

    # Variable reference
    rule(:variable_reference) do
      str("$") >> identifier.as(:variable)
    end

    # Message reference
    rule(:message_reference) do
      identifier.as(:message)
    end

    # Term reference
    rule(:term_reference) do
      str("-") >> identifier.as(:term)
    end

    # Function call
    rule(:function_call) do
      identifier.as(:function) >>
        str("(") >> function_arguments.as(:arguments) >> str(")")
    end

    # Function arguments
    rule(:function_arguments) do
      (inline_expression >> (str(",") >> space? >> inline_expression).repeat).maybe
    end

    # Select expression
    rule(:select_expression) do
      inline_expression.as(:selector) >> space? >>
        str("->") >> space? >> (eol >> space?).maybe >>
        variant.repeat(1).as(:variants)
    end

    # Variant
    rule(:variant) do
      space? >> str("[") >>
        (str("*").maybe.as(:default) >> variant_key).as(:key) >>
        str("]") >> space? >> pattern.as(:value)
    end

    # Variant key
    rule(:variant_key) do
      identifier.as(:identifier) | number.as(:number)
    end

    # Number
    rule(:number) do
      match("[0-9]").repeat(1)
    end

    # Attribute
    rule(:attribute) do
      eol >> space? >> str(".") >> identifier.as(:name) >>
        space? >> str("=") >> space? >> pattern.as(:value)
    end

    # Root rules
    rule(:resource) do
      (entry | space | comment | eol).repeat.as(:resource)
    end

    rule(:entry) do
      message | term
    end

    # Term
    rule(:term) do
      str("-") >> identifier.as(:id) >> space? >> str("=") >> space? >>
        pattern.as(:value) >>
        attribute.repeat.as(:attributes) >> line_end
    end

    # Parse entry point
    root(:resource)
  end
end
