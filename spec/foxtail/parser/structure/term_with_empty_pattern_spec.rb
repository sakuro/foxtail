# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with empty pattern in terms", ftl_fixture: "structure/term_with_empty_pattern" do
      include_examples "a valid FTL resource"
      it "treats terms with empty patterns as junk" do
        # Verify that all entries are Junk
        expect(result.body.size).to eq(3)
        expect(result.body.all?(Foxtail::AST::Junk)).to be true

        # Verify the first Junk (term with attribute)
        expect(result.body[0].content).to include("-foo =")
        expect(result.body[0].content).to include(".attr = Attribute")
        expect(result.body[0].annotations).not_to be_empty
        expect(result.body[0].annotations.any? {|a| a.message.include?("Expected term") && a.message.include?("to have a value") }).to be true

        # Verify the second Junk (term without attribute)
        expect(result.body[1].content).to include("-bar =")
        expect(result.body[1].annotations).not_to be_empty
        expect(result.body[1].annotations.any? {|a| a.message.include?("Expected term") && a.message.include?("to have a value") }).to be true

        # Verify the third Junk (term without equals sign)
        expect(result.body[2].content).to include("-baz")
        expect(result.body[2].annotations).not_to be_empty
        expect(result.body[2].annotations.any? {|a| a.message.include?("Expected token: =") }).to be true
      end
    end
  end
end
