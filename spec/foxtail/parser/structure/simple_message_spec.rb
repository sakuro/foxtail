# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with simple message", ftl_fixture: "structure/simple_message" do
      it "parses correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains one Message
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Verify the Message content
        message = result.body[0]
        expect(message.id.name).to eq("foo")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Foo")
        expect(message.attributes).to be_empty
        expect(message.comment).to be_nil
      end
    end
  end
end
