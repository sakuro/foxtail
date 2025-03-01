# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with control characters", ftl_fixture: "reference/any_char" do
      it "parses control characters correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains three Messages
        expect(result.body.size).to eq(3)
        expect(result.body.all?(Foxtail::AST::Message)).to be true

        # Verify the first message (with BEL character)
        message1 = result.body[0]
        expect(message1.id.name).to eq("control0")
        expect(message1.value).to be_a(Foxtail::AST::Pattern)
        expect(message1.value.elements.size).to eq(1)
        expect(message1.value.elements[0]).to be_a(Foxtail::AST::TextElement)

        # Define control character
        bel = "\u0007" # BEL U+0007
        expect(message1.value.elements[0].value).to eq("abc#{bel}def")

        expect(message1.comment).not_to be_nil
        # Use include instead of eq for more flexibility
        # The actual content has "BEL, U+0007" with a comma
        expect(message1.comment.content).to include("BEL, U+0007")

        # Verify the second message (with DEL character)
        message2 = result.body[1]
        expect(message2.id.name).to eq("delete")
        expect(message2.value).to be_a(Foxtail::AST::Pattern)
        expect(message2.value.elements.size).to eq(1)
        expect(message2.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        # Define control character
        del = "\u007F" # DEL U+007F
        expect(message2.value.elements[0].value).to eq("abc#{del}def")
        expect(message2.comment).not_to be_nil
        expect(message2.comment.content).to include("DEL, U+007F")

        # Verify the third message (with BPM character)
        message3 = result.body[2]
        expect(message3.id.name).to eq("control1")
        expect(message3.value).to be_a(Foxtail::AST::Pattern)
        expect(message3.value.elements.size).to eq(1)
        expect(message3.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        # Define control character
        bpm = "\u0082" # BPM U+0082
        expect(message3.value.elements[0].value).to eq("abc#{bpm}def")
        expect(message3.comment).not_to be_nil
        expect(message3.comment.content).to include("BPM, U+0082")
      end
    end
  end
end
