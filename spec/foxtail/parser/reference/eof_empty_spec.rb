# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with empty file", ftl_fixture: "reference/eof_empty" do
      include_examples "a valid FTL resource"
      it "parses empty file correctly" do
        # Verify that the body is empty
        expect(result.body).to be_empty
      end
    end
  end
end
