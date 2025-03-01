# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with variable reference", ftl_fixture: "reference/variable_reference" do
      it "parses correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains one Message
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Verify the Message content
        message = result.body[0]
        expect(message.id.name).to eq("welcome")
        expect(message.value).to be_a(Foxtail::AST::Pattern)

        # Verify the Pattern content
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
