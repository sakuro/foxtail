# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with select expressions", ftl_fixture: "reference/select_expressions" do
      it "parses select expressions correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Select expression using function call
        builtin_select = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "new-messages"
        }
        expect(builtin_select).not_to be_nil
        expect(builtin_select.value).to be_a(Foxtail::AST::Pattern)
        expect(builtin_select.value.elements.size).to eq(1)
        expect(builtin_select.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(builtin_select.value.elements[0].expression).to be_a(Foxtail::AST::SelectExpression)

        # Verify the SelectExpression content
        select_expr = builtin_select.value.elements[0].expression
        expect(select_expr.selector).to be_a(Foxtail::AST::FunctionReference)
        expect(select_expr.selector.id.name).to eq("BUILTIN")

        # Verify the Variants content
        expect(select_expr.variants.size).to eq(2)
        expect(select_expr.variants[0]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[0].key).to be_a(Foxtail::AST::NumberLiteral)
        expect(select_expr.variants[0].key.value).to eq("0")
        expect(select_expr.variants[0].value).to be_a(Foxtail::AST::Pattern)
        expect(select_expr.variants[0].value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(select_expr.variants[0].value.elements[0].value).to eq("Zero")
        expect(select_expr.variants[0].default).to be_falsey

        # Second variant
        expect(select_expr.variants[1]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[1].key.name).to eq("other")
        expect(select_expr.variants[1].value).to be_a(Foxtail::AST::Pattern)
        expect(select_expr.variants[1].value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(select_expr.variants[1].value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(select_expr.variants[1].value.elements[0].expression.value).to eq("")
        expect(select_expr.variants[1].default).to be_truthy

        # Select expression using term attribute
        term_attr_select = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "valid-selector-term-attribute"
        }
        expect(term_attr_select).not_to be_nil
        expect(term_attr_select.value).to be_a(Foxtail::AST::Pattern)
        expect(term_attr_select.value.elements.size).to eq(1)
        expect(term_attr_select.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(term_attr_select.value.elements[0].expression).to be_a(Foxtail::AST::SelectExpression)

        # Verify the SelectExpression content
        select_expr = term_attr_select.value.elements[0].expression
        expect(select_expr.selector).to be_a(Foxtail::AST::TermReference)
        expect(select_expr.selector.id.name).to eq("term")
        expect(select_expr.selector.attribute).to be_a(Foxtail::AST::Identifier)
        expect(select_expr.selector.attribute.name).to eq("case")

        # Verify the Variants content
        expect(select_expr.variants.size).to eq(1)
        expect(select_expr.variants[0]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[0].key.name).to eq("key")
        expect(select_expr.variants[0].value).to be_a(Foxtail::AST::Pattern)
        expect(select_expr.variants[0].value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(select_expr.variants[0].value.elements[0].value).to eq("value")
        expect(select_expr.variants[0].default).to be_truthy
      end
    end
  end
end
