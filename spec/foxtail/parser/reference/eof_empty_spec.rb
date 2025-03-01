# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with empty file", ftl_fixture: "reference/eof_empty" do
      it "parses empty file correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body is empty
        expect(result.body).to be_empty
      end
    end
  end
end
