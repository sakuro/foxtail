# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with multiline pattern", ftl_fixture: "structure/multiline_pattern" do
      include_examples "a valid FTL resource"
      it "parses multiline patterns correctly" do
        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Verify the key01 message
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key01" }
        expect(message).not_to be_nil
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Value\nContinued here.")

        # Verify the key02 message
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key02" }
        expect(message).not_to be_nil
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Value\nContinued here.")
      end
    end
  end
end
