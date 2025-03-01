# frozen_string_literal: true

require "parslet"

module Foxtail
  class Transform < Parslet::Transform
    # Text element transformation
    rule(text: simple(:text)) do
      AST::TextElement.new(text.to_s)
    end

    # Variable reference transformation
    rule(variable: simple(:name)) do
      AST::VariableReference.new(name.to_s)
    end

    # Placeable transformation
    rule(expression: simple(:expr)) do
      AST::Placeable.new(expr)
    end

    # Pattern transformation
    rule(pattern: sequence(:elements)) do
      AST::Pattern.new(elements)
    end

    # Empty pattern transformation
    rule(pattern: simple(:element)) do
      AST::Pattern.new([element])
    end

    # Variant transformation
    rule(
      key: simple(:key),
      value: simple(:value),
      default: simple(:default)
    ) do
      AST::Variant.new(key.to_s, value, default == "*")
    end

    # Select expression transformation
    rule(
      selector: simple(:selector),
      variants: sequence(:variants)
    ) do
      AST::SelectExpression.new(selector, variants)
    end

    # Attribute transformation
    rule(
      name: simple(:name),
      value: simple(:value)
    ) do
      [name.to_s, value]
    end

    # Message transformation
    rule(
      id: simple(:id),
      value: simple(:value),
      attributes: sequence(:attrs)
    ) do
      if id.to_s.start_with?("-")
        AST::Term.new(id.to_s[1..-1], value, Hash[attrs])
      else
        AST::Message.new(id.to_s, value, Hash[attrs])
      end
    end

    # Resource transformation
    rule(resource: sequence(:entries)) do
      AST::Resource.new(entries.compact)
    end
  end
end
