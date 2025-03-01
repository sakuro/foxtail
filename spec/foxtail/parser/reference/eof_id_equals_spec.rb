# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with identifier and equals at EOF", ftl_fixture: "reference/eof_id_equals" do
      it "parses identifier and equals at EOF correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains a ResourceComment and a Junk
        expect(result.body.size).to eq(2)
        expect(result.body[0]).to be_a(Foxtail::AST::ResourceComment)
        expect(result.body[1]).to be_a(Foxtail::AST::Junk)

        # Verify the content of the junk
        expect(result.body[1].content).to eq("message-id =")
      end
    end
  end
end
