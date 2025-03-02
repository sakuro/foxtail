# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with junk at EOF", ftl_fixture: "reference/eof_junk" do
      include_examples "a valid FTL resource"
      it "parses junk at EOF correctly" do
        # Verify that the body contains a ResourceComment and a Junk
        expect(result.body.size).to eq(2)
        expect(result.body[0]).to be_a(Foxtail::AST::ResourceComment)
        expect(result.body[1]).to be_a(Foxtail::AST::Junk)

        # Verify the content of the junk
        expect(result.body[1].content).to eq("000")
      end
    end
  end
end
