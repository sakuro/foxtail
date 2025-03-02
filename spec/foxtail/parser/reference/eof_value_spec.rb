# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with value at EOF", ftl_fixture: "reference/eof_value" do
      include_examples "a valid FTL resource"
      it "parses value at EOF correctly" do
        # Verify that the body contains a ResourceComment and a Message
        expect(result.body.size).to eq(2)
        expect(result.body[0]).to be_a(Foxtail::AST::ResourceComment)
        expect(result.body[1]).to be_a(Foxtail::AST::Message)

        # Verify the message
        message = result.body[1]
        expect(message.id.name).to eq("no-eol")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("No EOL")
      end
    end
  end
end
