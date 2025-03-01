# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with term", ftl_fixture: "structure/term" do
      it "parses term definition and references correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Verify that the first entry is a Term
        expect(result.body[0]).to be_a(Foxtail::AST::Term)
        term = result.body[0]
        expect(term.id.name).to eq("term")

        # Verify that the Term value is a Pattern
        expect(term.value).to be_a(Foxtail::AST::Pattern)
        expect(term.value.elements.size).to eq(1)
        expect(term.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Verify the Placeable content
        placeable = term.value.elements[0]
        expect(placeable.expression).to be_a(Foxtail::AST::SelectExpression)

        # Verify the SelectExpression content
        select_expr = placeable.expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("case")

        # Verify the Variants content
        expect(select_expr.variants.size).to eq(2)
        expect(select_expr.variants[0]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[0].key.name).to eq("uppercase")
        expect(select_expr.variants[0].default).to be_truthy

        # Verify the attributes
        expect(term.attributes.size).to eq(1)
        expect(term.attributes[0]).to be_a(Foxtail::AST::Attribute)
        expect(term.attributes[0].id.name).to eq("attr")

        # Verify that the second entry is a Message
        expect(result.body[1]).to be_a(Foxtail::AST::Message)
        message = result.body[1]
        expect(message.id.name).to eq("key01")

        # Verify that the Message value is a Pattern
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Verify the Placeable content
        placeable = message.value.elements[0]
        expect(placeable.expression).to be_a(Foxtail::AST::TermReference)
        expect(placeable.expression.id.name).to eq("term")
      end
    end
  end
end
