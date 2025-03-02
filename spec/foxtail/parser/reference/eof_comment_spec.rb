# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with EOF comment", ftl_fixture: "reference/eof_comment" do
      include_examples "a valid FTL resource"
      it "parses comment at EOF correctly" do
        # Verify that the body contains a ResourceComment and a Comment
        expect(result.body.size).to eq(2)
        expect(result.body[0]).to be_a(Foxtail::AST::ResourceComment)
        expect(result.body[1]).to be_a(Foxtail::AST::Comment)

        # Verify the content of the comments
        expect(result.body[0].content).to include("Disable final newline")
        expect(result.body[1].content).to eq("No EOL")
      end
    end
  end
end
