# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with CRLF line endings", ftl_fixture: "reference/crlf" do
      include_examples "a valid FTL resource"
      it "parses CRLF line endings correctly" do
        # Verify that the body contains expected entries
        expect(result.body.size).to eq(6)

        # Verify the first message
        message1 = result.body[0]
        expect(message1).to be_a(Foxtail::AST::Message)
        expect(message1.id.name).to eq("key01")
        expect(message1.value.elements[0].value).to eq("Value 01")

        # Verify the second message with attributes
        message2 = result.body[1]
        expect(message2).to be_a(Foxtail::AST::Message)
        expect(message2.id.name).to eq("key02")
        expect(message2.value.elements[0].value).to eq("Value 02\nContinued")
        expect(message2.attributes.size).to eq(1)
        expect(message2.attributes[0].id.name).to eq("title")
        expect(message2.attributes[0].value.elements[0].value).to eq("Title")

        # Verify the comment
        expect(result.body[2]).to be_a(Foxtail::AST::Comment)
        expect(result.body[2].content).to eq("ERROR Unclosed StringLiteral")

        # Verify the junk entries
        expect(result.body[3]).to be_a(Foxtail::AST::Junk)
        expect(result.body[3].content).to include("err03 = { \"str")

        expect(result.body[4]).to be_a(Foxtail::AST::Comment)
        expect(result.body[4].content).to eq("ERROR Missing newline after ->.")

        expect(result.body[5]).to be_a(Foxtail::AST::Junk)
        expect(result.body[5].content).to include("err04 = { $sel -> }")
      end
    end
  end
end
