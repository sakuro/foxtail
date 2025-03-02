# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with resource comment", ftl_fixture: "structure/resource_comment" do
      include_examples "a valid FTL resource"
      it "parses resource comment correctly" do
        # Verify that the body contains one ResourceComment
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::ResourceComment)

        # Verify the ResourceComment content
        comment = result.body[0]
        expect(comment.content).to include("This is a resource wide comment")
        expect(comment.content).to include("It's multiline")
      end
    end
  end
end
