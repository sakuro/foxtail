# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with placeable in placeable", ftl_fixture: "structure/placeable_in_placeable" do
      it "parses nested placeables correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Verify that the first entry is a Message
        expect(result.body[0]).to be_a(Foxtail::AST::Message)
        message = result.body[0]
        expect(message.id.name).to eq("key1")

        # Verify that the Message value is a Pattern
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Verify the outer Placeable content
        outer_placeable = message.value.elements[0]
        expect(outer_placeable.expression).to be_a(Foxtail::AST::Placeable)

        # Verify the inner Placeable content
        inner_placeable = outer_placeable.expression
        expect(inner_placeable.expression).to be_a(Foxtail::AST::MessageReference)
        expect(inner_placeable.expression.id.name).to eq("foo")
      end
    end
  end
end
