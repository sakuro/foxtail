# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with CR line endings", ftl_fixture: "reference/cr" do
      it "parses CR line endings correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains a ResourceComment
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::ResourceComment)

        # Verify the content of the ResourceComment
        expect(result.body[0].content).to include("This entire file uses CR as EOL")
      end
    end
  end
end
