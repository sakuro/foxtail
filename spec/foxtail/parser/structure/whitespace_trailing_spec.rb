# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with trailing whitespace", ftl_fixture: "structure/whitespace_trailing" do
      include_examples "a valid FTL resource"
      it "parses trailing whitespace correctly" do
        # Verify that the body contains four Messages
        expect(result.body.size).to eq(4)
        expect(result.body.all?(Foxtail::AST::Message)).to be true

        # Verify the first message (with trailing whitespace in value)
        message1 = result.body[0]
        expect(message1.id.name).to eq("key1")
        expect(message1.value).to be_a(Foxtail::AST::Pattern)
        expect(message1.value.elements.size).to eq(1)
        expect(message1.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message1.value.elements[0].value).to eq("Value")
        expect(message1.comment).not_to be_nil
        expect(message1.comment.content).to eq("          < whitespace >")

        # Verify the second message (with non-breaking space)
        message2 = result.body[1]
        expect(message2.id.name).to eq("key2")
        expect(message2.value).to be_a(Foxtail::AST::Pattern)
        expect(message2.value.elements.size).to eq(1)
        expect(message2.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        # The comment "↓ nbsp" in the FTL file indicates a non-breaking space
        # Based on our debugging, the actual string contains "Value" followed by
        # three regular spaces and one non-breaking space
        nbsp = "\u00A0"  # Non-breaking space (U+00A0)
        space = " "      # Regular space

        # Use variables in the comparison for better readability
        value = message2.value.elements[0].value
        # "Value" followed by 3 regular spaces, then 1 non-breaking space at the end
        expected = "Value#{space}#{space}#{space}#{nbsp}"
        expect(value).to eq(expected)
        expect(message2.comment).not_to be_nil
        expect(message2.comment.content).to eq("             ↓ nbsp")

        # Verify the third message (with trailing whitespace before placeable)
        message3 = result.body[2]
        expect(message3.id.name).to eq("key3")
        expect(message3.value).to be_a(Foxtail::AST::Pattern)
        expect(message3.value.elements.size).to eq(3)
        expect(message3.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message3.value.elements[0].value).to eq("Value              ")
        expect(message3.value.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(message3.value.elements[1].expression).to be_a(Foxtail::AST::MessageReference)
        expect(message3.value.elements[1].expression.id.name).to eq("placeable")
        expect(message3.value.elements[2]).to be_a(Foxtail::AST::TextElement)
        expect(message3.value.elements[2].value).to eq(".")

        # Verify the fourth message (with whitespace in string placeable)
        message4 = result.body[3]
        expect(message4.id.name).to eq("key4")
        expect(message4.value).to be_a(Foxtail::AST::Pattern)
        expect(message4.value.elements.size).to eq(2)
        expect(message4.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message4.value.elements[0].value).to eq("Value")
        expect(message4.value.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(message4.value.elements[1].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(message4.value.elements[1].expression.value).to eq("           ")
      end
    end
  end
end
