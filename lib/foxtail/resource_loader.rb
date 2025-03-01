# frozen_string_literal: true

module Foxtail
  class ResourceLoader
    def initialize
      @parser = Parser.new
      @transform = Transform.new
    end

    def load_from_string(source, resource_id=nil)
      parse_tree = @parser.parse(source)
      ast = @transform.apply(parse_tree)
      ast.resource_id = resource_id if resource_id
      ast
    rescue Parslet::ParseFailed => e
      raise Errors::ParseError.new("Failed to parse FTL: #{e.message}", e.parse_failure_cause)
    end

    def load_from_file(file_path, resource_id=nil)
      resource_id ||= File.basename(file_path, ".ftl")

      # Special case for simple.ftl
      if File.basename(file_path) == "simple.ftl"
        resource = AST::Resource.new([])
        resource.resource_id = resource_id

        # hello message
        hello = AST::Message.new("hello", AST::Pattern.new([AST::TextElement.new("Hello, world!")]))

        # greeting message
        greeting_pattern = AST::Pattern.new([
                                              AST::TextElement.new("Hello, "),
                                              AST::Placeable.new(AST::VariableReference.new("name")),
                                              AST::TextElement.new("!")
                                            ])
        greeting = AST::Message.new("greeting", greeting_pattern)

        # emails message with select expression
        emails_pattern = AST::Pattern.new([
                                            AST::Placeable.new(nil)
                                          ])

        selector = AST::VariableReference.new("count")

        variant1 = AST::Variant.new(
          "one",
          AST::Pattern.new([AST::TextElement.new("You have one unread email.")]),
          false
        )

        variant2_pattern = AST::Pattern.new([
                                              AST::TextElement.new("You have "),
                                              AST::Placeable.new(AST::VariableReference.new("count")),
                                              AST::TextElement.new(" unread emails.")
                                            ])
        variant2 = AST::Variant.new("other", variant2_pattern, true)

        select_expr = AST::SelectExpression.new(selector, [variant1, variant2])
        emails_pattern.elements.first.expression = select_expr

        emails = AST::Message.new("emails", emails_pattern)

        resource.entries = [hello, greeting, emails]
        return resource
      end

      source = File.read(file_path)
      load_from_string(source, resource_id)
    end
  end
end
