# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with empty pattern in variants", ftl_fixture: "structure/variant_with_empty_pattern" do
      include_examples "a valid FTL resource"
      it "correctly handles variants with empty patterns" do
        # Verify that the body contains a Message and a Junk
        expect(result.body.size).to eq(2)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)
        expect(result.body[1]).to be_a(Foxtail::AST::Junk)

        # Verify the Message with empty string literal in variant
        message = result.body[0]
        expect(message.id.name).to eq("key1")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Verify the SelectExpression inside the Placeable
        select_expr = message.value.elements[0].expression
        expect(select_expr).to be_a(Foxtail::AST::SelectExpression)
        expect(select_expr.selector).to be_a(Foxtail::AST::NumberLiteral)
        expect(select_expr.selector.value).to eq("1")

        # Verify the Variant with empty string
        expect(select_expr.variants.size).to eq(1)
        variant = select_expr.variants[0]
        expect(variant.key.name).to eq("one")
        expect(variant.default).to be true
        expect(variant.value).to be_a(Foxtail::AST::Pattern)
        expect(variant.value.elements.size).to eq(1)
        expect(variant.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(variant.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(variant.value.elements[0].expression.value).to eq("")

        # Verify the Junk with variant without value
        junk = result.body[1]
        expect(junk.content).to include("err2 =")
        expect(junk.content).to include("{ $sel ->")
        expect(junk.content).to include("*[one]")
        expect(junk.annotations).not_to be_empty
        expect(junk.annotations.any? {|a| a.message.include?("Expected value") }).to be true
      end
    end
  end
end
