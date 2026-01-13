# frozen_string_literal: true

RSpec.describe Foxtail::Syntax::Visitor do
  let(:parser) { Foxtail::Syntax::Parser.new }

  describe "visit_* methods" do
    it "has visit methods for all AST node types" do
      visitor_class = Class.new { include Foxtail::Syntax::Visitor }
      visitor = visitor_class.new

      expected_methods = %i[
        visit_resource
        visit_message
        visit_term
        visit_attribute
        visit_pattern
        visit_placeable
        visit_select_expression
        visit_variant
        visit_call_arguments
        visit_named_argument
        visit_message_reference
        visit_term_reference
        visit_function_reference
        visit_variable_reference
        visit_string_literal
        visit_number_literal
        visit_text_element
        visit_identifier
        visit_comment
        visit_group_comment
        visit_resource_comment
        visit_junk
        visit_annotation
        visit_span
        visit_children
      ]

      expected_methods.each do |method|
        expect(visitor).to respond_to(method)
      end
    end

    it "returns nil by default for all visit methods" do
      visitor_class = Class.new { include Foxtail::Syntax::Visitor }
      visitor = visitor_class.new

      resource = parser.parse("hello = world")
      expect(visitor.visit_resource(resource)).to be_nil
      expect(visitor.visit_message(resource.body.first)).to be_nil
    end
  end

  describe "#accept" do
    it "dispatches to the correct visit method" do
      visited_types = []
      visitor_class = Class.new do
        include Foxtail::Syntax::Visitor

        define_method(:initialize) do
          @visited_types = visited_types
        end

        define_method(:visit_resource) do |node|
          @visited_types << :resource
          visit_children(node)
        end

        define_method(:visit_message) do |node|
          @visited_types << :message
          visit_children(node)
        end

        define_method(:visit_identifier) do |_node|
          @visited_types << :identifier
        end

        define_method(:visit_pattern) do |node|
          @visited_types << :pattern
          visit_children(node)
        end

        define_method(:visit_text_element) do |_node|
          @visited_types << :text_element
        end
      end

      resource = parser.parse("hello = world")
      visitor = visitor_class.new
      resource.accept(visitor)

      expect(visited_types).to eq(%i[resource message identifier pattern text_element])
    end
  end

  describe "#children" do
    it "returns correct children for Resource" do
      resource = parser.parse("hello = world\ngoodbye = bye")
      expect(resource.children.length).to eq(2)
      expect(resource.children).to all(be_a(Foxtail::Syntax::Parser::AST::Message))
    end

    it "returns correct children for Message" do
      resource = parser.parse("hello = world")
      message = resource.body.first
      children = message.children

      expect(children.length).to eq(2) # id and value (no attributes, no comment)
      expect(children[0]).to be_a(Foxtail::Syntax::Parser::AST::Identifier)
      expect(children[1]).to be_a(Foxtail::Syntax::Parser::AST::Pattern)
    end

    it "returns correct children for Pattern" do
      resource = parser.parse("hello = Hello { $name }")
      message = resource.body.first
      pattern = message.value

      expect(pattern.children.length).to eq(2)
      expect(pattern.children[0]).to be_a(Foxtail::Syntax::Parser::AST::TextElement)
      expect(pattern.children[1]).to be_a(Foxtail::Syntax::Parser::AST::Placeable)
    end

    it "returns correct children for SelectExpression" do
      ftl = <<~FTL
        count = { $num ->
            [one] One item
           *[other] { $num } items
        }
      FTL
      resource = parser.parse(ftl)
      message = resource.body.first
      placeable = message.value.elements.first
      select_expr = placeable.expression

      expect(select_expr.children.length).to eq(3) # selector + 2 variants
      expect(select_expr.children[0]).to be_a(Foxtail::Syntax::Parser::AST::VariableReference)
      expect(select_expr.children[1]).to be_a(Foxtail::Syntax::Parser::AST::Variant)
      expect(select_expr.children[2]).to be_a(Foxtail::Syntax::Parser::AST::Variant)
    end

    it "returns empty array for leaf nodes" do
      resource = parser.parse("hello = world")
      message = resource.body.first
      identifier = message.id
      text_element = message.value.elements.first

      expect(identifier.children).to eq([])
      expect(text_element.children).to eq([])
    end
  end

  describe "practical usage" do
    it "can collect all message IDs" do
      ids = []
      visitor_class = Class.new do
        include Foxtail::Syntax::Visitor

        define_method(:initialize) do
          @ids = ids
        end

        define_method(:visit_resource) do |node|
          visit_children(node)
        end

        define_method(:visit_message) do |node|
          @ids << node.id.name
        end
      end

      ftl = <<~FTL
        hello = Hello
        goodbye = Goodbye
        -brand = Firefox
        welcome = Welcome
      FTL
      resource = parser.parse(ftl)
      visitor = visitor_class.new
      resource.accept(visitor)

      expect(ids).to eq(%w[hello goodbye welcome])
    end

    it "can count all variable references" do
      count = {value: 0}
      visitor_class = Class.new do
        include Foxtail::Syntax::Visitor

        define_method(:initialize) do
          @count = count
        end

        define_method(:visit_resource) do |node|
          visit_children(node)
        end

        define_method(:visit_message) do |node|
          visit_children(node)
        end

        define_method(:visit_pattern) do |node|
          visit_children(node)
        end

        define_method(:visit_placeable) do |node|
          visit_children(node)
        end

        define_method(:visit_variable_reference) do |_node|
          @count[:value] += 1
        end
      end

      ftl = <<~FTL
        greeting = Hello { $name }, you have { $count } messages from { $sender }
      FTL
      resource = parser.parse(ftl)
      visitor = visitor_class.new
      resource.accept(visitor)

      expect(count[:value]).to eq(3)
    end
  end
end
