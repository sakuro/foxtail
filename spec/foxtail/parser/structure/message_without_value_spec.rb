# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with message without value", ftl_fixture: "structure/message_without_value" do
      it "parses as junk with error annotation" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains one Junk
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Junk)

        # Verify the Junk content
        junk = result.body[0]
        expect(junk.content).to eq("foo =\n")

        # Verify the annotations
        expect(junk.annotations.size).to eq(1)
        expect(junk.annotations[0]).to be_a(Foxtail::AST::Annotation)
        expect(junk.annotations[0].code).to eq("E0005")
        expect(junk.annotations[0].arguments).to eq(["foo"])
        expect(junk.annotations[0].message).to include("Expected message")
        expect(junk.annotations[0].message).to include("foo")
        expect(junk.annotations[0].message).to include("to have a value or attributes")
      end
    end
  end
end
