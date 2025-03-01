# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with simple message" do
      let(:ftl_file) { "spec/fixtures/structure/simple_message.ftl" }
      let(:json_file) { "spec/fixtures/structure/simple_message.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのMessageが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Messageの内容を確認
        message = result.body[0]
        expect(message.id.name).to eq("foo")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Foo")
        expect(message.attributes).to be_empty
        expect(message.comment).to be_nil
      end
    end

    context "with attribute" do
      let(:ftl_file) { "spec/fixtures/structure/attribute_starts_from_nl.ftl" }
      let(:json_file) { "spec/fixtures/structure/attribute_starts_from_nl.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのMessageが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Messageの内容を確認
        message = result.body[0]
        expect(message.id.name).to eq("foo")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Value")

        # 属性を確認
        expect(message.attributes.size).to eq(1)
        expect(message.attributes[0]).to be_a(Foxtail::AST::Attribute)
        expect(message.attributes[0].id.name).to eq("attr")
        expect(message.attributes[0].value).to be_a(Foxtail::AST::Pattern)
        expect(message.attributes[0].value.elements.size).to eq(1)
        expect(message.attributes[0].value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.attributes[0].value.elements[0].value).to eq("Value 2")
      end
    end

    context "with select expression" do
      let(:ftl_file) { "spec/fixtures/structure/select_expression.ftl" }
      let(:json_file) { "spec/fixtures/structure/select_expression.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのMessageが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Messageの内容を確認
        message = result.body[0]
        expect(message.id.name).to eq("emails")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Placeableの内容を確認
        placeable = message.value.elements[0]
        expect(placeable.expression).to be_a(Foxtail::AST::SelectExpression)

        # SelectExpressionの内容を確認
        select_expr = placeable.expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("count")

        # Variantsの内容を確認
        expect(select_expr.variants.size).to eq(2)
        expect(select_expr.variants[0]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[0].key.name).to eq("one")
        expect(select_expr.variants[0].value).to be_a(Foxtail::AST::Pattern)
        expect(select_expr.variants[0].value.elements[0].value).to eq("You have one new email.")
        expect(select_expr.variants[0].default).to be_falsey

        expect(select_expr.variants[1]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[1].key.name).to eq("other")
        expect(select_expr.variants[1].value).to be_a(Foxtail::AST::Pattern)
        expect(select_expr.variants[1].default).to be_truthy

        # "other" variantのPatternの内容を確認
        other_pattern = select_expr.variants[1].value
        expect(other_pattern.elements.size).to eq(3)
        expect(other_pattern.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(other_pattern.elements[0].value).to eq("You have ")
        expect(other_pattern.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(other_pattern.elements[1].expression).to be_a(Foxtail::AST::VariableReference)
        expect(other_pattern.elements[1].expression.id.name).to eq("count")
        expect(other_pattern.elements[2]).to be_a(Foxtail::AST::TextElement)
        expect(other_pattern.elements[2].value).to eq(" new emails.")
      end
    end

    context "with variable reference" do
      let(:ftl_file) { "spec/fixtures/reference/variable_reference.ftl" }
      let(:json_file) { "spec/fixtures/reference/variable_reference.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのMessageが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Messageの内容を確認
        message = result.body[0]
        expect(message.id.name).to eq("welcome")
        expect(message.value).to be_a(Foxtail::AST::Pattern)

        # Patternの内容を確認
        pattern = message.value
        expect(pattern.elements.size).to eq(3)
        expect(pattern.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(pattern.elements[0].value).to eq("Welcome, ")
        expect(pattern.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(pattern.elements[1].expression).to be_a(Foxtail::AST::VariableReference)
        expect(pattern.elements[1].expression.id.name).to eq("user")
        expect(pattern.elements[2]).to be_a(Foxtail::AST::TextElement)
        expect(pattern.elements[2].value).to eq("!")
      end
    end
  end
end
