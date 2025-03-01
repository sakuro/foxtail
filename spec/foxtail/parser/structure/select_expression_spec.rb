# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with select expression", ftl_fixture: "structure/select_expression" do
      it "parses correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains one Message
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Verify the Message content
        message = result.body[0]
        expect(message.id.name).to eq("emails")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Verify the Placeable content
        placeable = message.value.elements[0]
        expect(placeable.expression).to be_a(Foxtail::AST::SelectExpression)

        # Verify the SelectExpression content
        select_expr = placeable.expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("count")

        # Verify the Variants content
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

        # Verify the Pattern content of the "other" variant
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
  end
end
