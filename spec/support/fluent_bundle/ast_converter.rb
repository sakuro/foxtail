# frozen_string_literal: true

module FluentBundleCompatibility
  # Converts Bundle::AST entries to fluent-bundle JSON format
  module ASTConverter
    module_function

    def to_json_format(entries)
      {
        "body" => entries.map {|entry| entry_to_json(entry) }
      }
    end

    def entry_to_json(entry)
      {
        "id" => entry.id.sub(/^-/, ""), # fluent-bundle strips the leading dash for terms
        "value" => value_to_json(entry.value),
        "attributes" => attributes_to_json(entry.attributes)
      }
    end

    def value_to_json(value)
      case value
      when String
        value
      when Array
        value.map {|element| element_to_json(element) }
      when nil
        nil
      else
        element_to_json(value)
      end
    end

    def element_to_json(element)
      case element
      when String
        element
      when Foxtail::Bundle::AST::VariableReference
        {"type" => "var", "name" => element.name}
      when Foxtail::Bundle::AST::MessageReference
        {"type" => "mesg", "name" => element.name, "attr" => element.attr}
      when Foxtail::Bundle::AST::TermReference
        {"type" => "term", "name" => element.name, "attr" => element.attr}
      when Foxtail::Bundle::AST::FunctionReference
        {"type" => "func", "name" => element.name, "args" => args_to_json(element.args)}
      when Foxtail::Bundle::AST::NumberLiteral
        {"type" => "numb", "value" => element.value, "precision" => element.precision}
      when Foxtail::Bundle::AST::StringLiteral
        {"type" => "str", "value" => element.value}
      when Foxtail::Bundle::AST::SelectExpression
        {
          "type" => "select",
          "selector" => element_to_json(element.selector),
          "variants" => element.variants.map {|v| variant_to_json(v) },
          "star" => element.star
        }
      else
        element.to_s
      end
    end

    def args_to_json(args)
      args.map do |arg|
        case arg
        when Foxtail::Bundle::AST::NamedArgument
          {"type" => "narg", "name" => arg.name, "value" => element_to_json(arg.value)}
        else
          element_to_json(arg)
        end
      end
    end

    def variant_to_json(variant)
      {"key" => element_to_json(variant.key), "value" => value_to_json(variant.value)}
    end

    def attributes_to_json(attributes)
      return {} if attributes.nil?

      attributes.transform_values {|v| value_to_json(v) }
    end
  end
end
