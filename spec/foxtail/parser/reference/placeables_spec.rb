# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with placeables", ftl_fixture: "reference/placeables" do
      it "correctly parses placeables" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains three messages and four comments
        expect(result.body.size).to eq(11)
        expect(result.body.count {|entry| entry.is_a?(Foxtail::AST::Message) }).to eq(3)
        expect(result.body.count {|entry| entry.is_a?(Foxtail::AST::Comment) }).to eq(4)
        expect(result.body.count {|entry| entry.is_a?(Foxtail::AST::Junk) }).to eq(4)

        # Verify the nested placeable
        nested_placeable = result.body[0]
        expect(nested_placeable).to be_a(Foxtail::AST::Message)
        expect(nested_placeable.id.name).to eq("nested-placeable")

        placeable1 = nested_placeable.value.elements[0]
        expect(placeable1).to be_a(Foxtail::AST::Placeable)

        placeable2 = placeable1.expression
        expect(placeable2).to be_a(Foxtail::AST::Placeable)

        placeable3 = placeable2.expression
        expect(placeable3).to be_a(Foxtail::AST::Placeable)

        number = placeable3.expression
        expect(number).to be_a(Foxtail::AST::NumberLiteral)
        expect(number.value).to eq("1")

        # Verify the padded placeable
        padded_placeable = result.body[1]
        expect(padded_placeable).to be_a(Foxtail::AST::Message)
        expect(padded_placeable.id.name).to eq("padded-placeable")

        placeable = padded_placeable.value.elements[0]
        expect(placeable).to be_a(Foxtail::AST::Placeable)

        number = placeable.expression
        expect(number).to be_a(Foxtail::AST::NumberLiteral)
        expect(number.value).to eq("1")

        # Verify the sparse placeable
        sparse_placeable = result.body[2]
        expect(sparse_placeable).to be_a(Foxtail::AST::Message)
        expect(sparse_placeable.id.name).to eq("sparse-placeable")

        placeable1 = sparse_placeable.value.elements[0]
        expect(placeable1).to be_a(Foxtail::AST::Placeable)

        placeable2 = placeable1.expression
        expect(placeable2).to be_a(Foxtail::AST::Placeable)

        number = placeable2.expression
        expect(number).to be_a(Foxtail::AST::NumberLiteral)
        expect(number.value).to eq("1")

        # Verify that unmatched braces are treated as Junk
        comments = result.body.select {|entry| entry.is_a?(Foxtail::AST::Comment) }
        expect(comments.size).to eq(4)

        expect(comments[0].content).to eq("ERROR Unmatched opening brace")
        expect(comments[1].content).to eq("ERROR Unmatched opening brace")
        expect(comments[2].content).to eq("ERROR Unmatched closing brace")
        expect(comments[3].content).to eq("ERROR Unmatched closing brace")

        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(4)

        expect(junk_entries[0].content).to include("unmatched-open1 = { 1")
        expect(junk_entries[1].content).to include("unmatched-open2 = {{ 1 }")
        expect(junk_entries[2].content).to include("unmatched-close1 = 1 }")
        expect(junk_entries[3].content).to include("unmatched-close2 = { 1 }}")
      end
    end
  end
end
