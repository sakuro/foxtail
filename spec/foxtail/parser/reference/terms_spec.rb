# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with terms", ftl_fixture: "reference/terms" do
      it "correctly parses term definitions" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Helper method to find a term by ID
        def find_term(id)
          result.body.find {|entry| entry.is_a?(Foxtail::AST::Term) && entry.id.name == id }
        end

        # Verify term with attribute
        term01 = find_term("term01")
        expect(term01).not_to be_nil
        expect(term01.value).to be_a(Foxtail::AST::Pattern)
        expect(term01.value.elements.size).to eq(1)
        expect(term01.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(term01.value.elements[0].value).to eq("Value")
        expect(term01.attributes.size).to eq(1)
        expect(term01.attributes[0].id.name).to eq("attr")
        expect(term01.attributes[0].value.elements[0].value).to eq("Attribute")

        # Verify term with empty string
        term02 = find_term("term02")
        expect(term02).not_to be_nil
        expect(term02.value).to be_a(Foxtail::AST::Pattern)
        expect(term02.value.elements.size).to eq(1)
        expect(term02.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(term02.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(term02.value.elements[0].expression.value).to eq("")
        expect(term02.attributes).to be_empty

        # Verify that invalid terms are treated as Junk
        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(5)

        # Verify that each Junk entry contains the expected content
        expect(junk_entries[0].content).to include("-term03 =")
        expect(junk_entries[0].content).to include(".attr = Attribute")
        expect(junk_entries[1].content).to include("-term04 =")
        expect(junk_entries[1].content).to include(".attr1 = Attribute 1")
        expect(junk_entries[2].content).to include("-term05 =")
        expect(junk_entries[3].content).to include("-term06 =")
        expect(junk_entries[4].content).to include("-term07")

        # Verify term with no whitespace
        term08 = find_term("term08")
        expect(term08).not_to be_nil
        expect(term08.value).to be_a(Foxtail::AST::Pattern)
        expect(term08.value.elements[0].value).to eq("Value")
        expect(term08.attributes.size).to eq(1)
        expect(term08.attributes[0].id.name).to eq("attr")
        expect(term08.attributes[0].value.elements[0].value).to eq("Attribute")

        # Verify term with extra whitespace
        term09 = find_term("term09")
        expect(term09).not_to be_nil
        expect(term09.value).to be_a(Foxtail::AST::Pattern)
        expect(term09.value.elements[0].value).to eq("Value")
        expect(term09.attributes.size).to eq(1)
        expect(term09.attributes[0].id.name).to eq("attr")
        expect(term09.attributes[0].value.elements[0].value).to eq("Attribute")
      end
    end
  end
end
