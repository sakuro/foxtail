# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with mixed entries", ftl_fixture: "reference/mixed_entries" do
      it "correctly parses a mix of different entry types" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify the standalone comment
        standalone_comment = result.body[0]
        expect(standalone_comment).to be_a(Foxtail::AST::Comment)
        expect(standalone_comment.content).to eq("License Comment")

        # Verify the resource comment
        resource_comment = result.body[1]
        expect(resource_comment).to be_a(Foxtail::AST::ResourceComment)
        expect(resource_comment.content).to eq("Resource Comment")

        # Verify the term
        term = result.body[2]
        expect(term).to be_a(Foxtail::AST::Term)
        expect(term.id.name).to eq("brand-name")
        expect(term.value).to be_a(Foxtail::AST::Pattern)
        expect(term.value.elements[0].value).to eq("Aurora")
        expect(term.attributes).to be_empty

        # Verify the group comment
        group_comment = result.body[3]
        expect(group_comment).to be_a(Foxtail::AST::GroupComment)
        expect(group_comment.content).to eq("Group Comment")

        # Verify the message with no value but with attribute
        key01 = result.body[4]
        expect(key01).to be_a(Foxtail::AST::Message)
        expect(key01.id.name).to eq("key01")
        expect(key01.value).to be_nil
        expect(key01.attributes.size).to eq(1)
        expect(key01.attributes[0].id.name).to eq("attr")
        expect(key01.attributes[0].value.elements[0].value).to eq("Attribute")

        # Verify that invalid entries are treated as Junk
        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(2)

        # Verify that each Junk entry contains the expected content
        expect(junk_entries[0].content).to include("ą=Invalid identifier")
        expect(junk_entries[0].content).to include("ć=Another one")
        expect(junk_entries[1].content).to include(".attr = Dangling attribute")

        # Verify the message with comment
        key02 = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key02" }
        expect(key02).not_to be_nil
        expect(key02.value).to be_a(Foxtail::AST::Pattern)
        expect(key02.value.elements[0].value).to eq("Value")
        expect(key02.attributes).to be_empty
        expect(key02.comment).to be_a(Foxtail::AST::Comment)
        expect(key02.comment.content).to eq("Message Comment")

        # Verify the standalone comment
        standalone_comment2 = result.body[7]
        expect(standalone_comment2).to be_a(Foxtail::AST::Comment)
        expect(standalone_comment2.content).to eq("Standalone Comment")

        # Verify the message with comment
        key03 = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key03" }
        expect(key03).not_to be_nil
        expect(key03.value).to be_a(Foxtail::AST::Pattern)
        expect(key03.value.elements[0].value).to eq("Value 03")
        expect(key03.attributes).to be_empty
        expect(key03.comment).to be_a(Foxtail::AST::Comment)
        expect(key03.comment.content).to eq("There are 5 spaces on the line between key03 and key04.")

        # Verify the message
        key04 = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key04" }
        expect(key04).not_to be_nil
        expect(key04.value).to be_a(Foxtail::AST::Pattern)
        expect(key04.value.elements[0].value).to eq("Value 04")
        expect(key04.attributes).to be_empty
        expect(key04.comment).to be_nil
      end
    end
  end
end
