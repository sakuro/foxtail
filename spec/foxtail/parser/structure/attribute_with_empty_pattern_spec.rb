# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with empty pattern in attributes", ftl_fixture: "structure/attribute_with_empty_pattern" do
      it "treats attributes with empty patterns as junk" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that all entries are Junk
        expect(result.body.size).to eq(5)
        expect(result.body.all?(Foxtail::AST::Junk)).to be true

        # Verify that each Junk has an annotation with "Expected value"
        result.body.each do |junk|
          expect(junk.annotations).not_to be_empty
          expect(junk.annotations.any? {|a| a.message.include?("Expected value") }).to be true
        end
      end
    end
  end
end
