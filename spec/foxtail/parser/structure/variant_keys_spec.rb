# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with variant keys", ftl_fixture: "structure/variant_keys" do
      include_examples "a valid FTL resource"
      it "parses variant keys correctly" do
        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Verify the key01 message
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key01" }
        expect(message).not_to be_nil
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(message.value.elements[0].expression).to be_a(Foxtail::AST::SelectExpression)

        # Verify the SelectExpression content
        select_expr = message.value.elements[0].expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("sel")
        expect(select_expr.variants.size).to eq(1)
        expect(select_expr.variants[0].key.name).to eq("key")
        expect(select_expr.variants[0].default).to be_truthy

        # Verify the key02 message
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key02" }
        expect(message).not_to be_nil
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(message.value.elements[0].expression).to be_a(Foxtail::AST::SelectExpression)

        # Verify the SelectExpression content
        select_expr = message.value.elements[0].expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("sel")
        expect(select_expr.variants.size).to eq(1)
        expect(select_expr.variants[0].key.name).to eq("key")
        expect(select_expr.variants[0].default).to be_truthy
      end
    end
  end
end
