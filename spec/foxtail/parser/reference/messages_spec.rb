# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with messages", ftl_fixture: "reference/messages" do
      it "correctly parses different message formats" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Helper method to find a message by ID
        def find_message(id)
          result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == id }
        end

        # Verify simple message
        key01 = find_message("key01")
        expect(key01).not_to be_nil
        expect(key01.value).to be_a(Foxtail::AST::Pattern)
        expect(key01.value.elements[0].value).to eq("Value")
        expect(key01.attributes).to be_empty

        # Verify message with one attribute
        key02_with_attr = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) &&
            entry.id.name == "key02" &&
            entry.attributes.size == 1
        }
        expect(key02_with_attr).not_to be_nil
        expect(key02_with_attr.value).to be_a(Foxtail::AST::Pattern)
        expect(key02_with_attr.value.elements[0].value).to eq("Value")
        expect(key02_with_attr.attributes.size).to eq(1)
        expect(key02_with_attr.attributes[0].id.name).to eq("attr")
        expect(key02_with_attr.attributes[0].value.elements[0].value).to eq("Attribute")

        # Verify message with multiple attributes
        key02_with_attrs = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) &&
            entry.id.name == "key02" &&
            entry.attributes.size == 2
        }
        expect(key02_with_attrs).not_to be_nil
        expect(key02_with_attrs.value).to be_a(Foxtail::AST::Pattern)
        expect(key02_with_attrs.value.elements[0].value).to eq("Value")
        expect(key02_with_attrs.attributes.size).to eq(2)
        expect(key02_with_attrs.attributes[0].id.name).to eq("attr1")
        expect(key02_with_attrs.attributes[0].value.elements[0].value).to eq("Attribute 1")
        expect(key02_with_attrs.attributes[1].id.name).to eq("attr2")
        expect(key02_with_attrs.attributes[1].value.elements[0].value).to eq("Attribute 2")

        # Verify message with no value but with attribute
        key03 = find_message("key03")
        expect(key03).not_to be_nil
        expect(key03.value).to be_nil
        expect(key03.attributes.size).to eq(1)
        expect(key03.attributes[0].id.name).to eq("attr")
        expect(key03.attributes[0].value.elements[0].value).to eq("Attribute")

        # Verify message with no value but with multiple attributes
        key04 = find_message("key04")
        expect(key04).not_to be_nil
        expect(key04.value).to be_nil
        expect(key04.attributes.size).to eq(2)
        expect(key04.attributes[0].id.name).to eq("attr1")
        expect(key04.attributes[0].value.elements[0].value).to eq("Attribute 1")
        expect(key04.attributes[1].id.name).to eq("attr2")
        expect(key04.attributes[1].value.elements[0].value).to eq("Attribute 2")

        # Verify message with comment
        key05 = find_message("key05")
        expect(key05).not_to be_nil
        expect(key05.value).to be_nil
        expect(key05.attributes.size).to eq(1)
        expect(key05.attributes[0].id.name).to eq("attr1")
        expect(key05.attributes[0].value.elements[0].value).to eq("Attribute 1")
        expect(key05.comment).not_to be_nil
        expect(key05.comment.content).to eq("     <  whitespace  >")

        # Verify message with no whitespace
        no_whitespace = find_message("no-whitespace")
        expect(no_whitespace).not_to be_nil
        expect(no_whitespace.value).to be_a(Foxtail::AST::Pattern)
        expect(no_whitespace.value.elements[0].value).to eq("Value")
        expect(no_whitespace.attributes.size).to eq(1)
        expect(no_whitespace.attributes[0].id.name).to eq("attr1")
        expect(no_whitespace.attributes[0].value.elements[0].value).to eq("Attribute 1")

        # Verify message with extra whitespace
        extra_whitespace = find_message("extra-whitespace")
        expect(extra_whitespace).not_to be_nil
        expect(extra_whitespace.value).to be_a(Foxtail::AST::Pattern)
        expect(extra_whitespace.value.elements[0].value).to eq("Value")
        expect(extra_whitespace.attributes.size).to eq(1)
        expect(extra_whitespace.attributes[0].id.name).to eq("attr1")
        expect(extra_whitespace.attributes[0].value.elements[0].value).to eq("Attribute 1")

        # Verify message with empty string
        key06 = find_message("key06")
        expect(key06).not_to be_nil
        expect(key06.value).to be_a(Foxtail::AST::Pattern)
        expect(key06.value.elements.size).to eq(1)
        expect(key06.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(key06.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(key06.value.elements[0].expression.value).to eq("")

        # Verify that invalid messages are treated as Junk
        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(5)

        # Verify that each Junk entry contains the expected content
        expect(junk_entries[0].content).to include("key07 =")
        expect(junk_entries[1].content).to include("key08")
        expect(junk_entries[2].content).to include("0err-14 = Value 14")
        expect(junk_entries[3].content).to include("err-15? = Value 15")
        expect(junk_entries[4].content).to include("err-ąę-16 = Value 16")

        # Verify messages with different identifier formats
        key09 = find_message("KEY09")
        expect(key09).not_to be_nil
        expect(key09.value).to be_a(Foxtail::AST::Pattern)
        expect(key09.value.elements[0].value).to eq("Value 09")

        key10 = find_message("key-10")
        expect(key10).not_to be_nil
        expect(key10.value).to be_a(Foxtail::AST::Pattern)
        expect(key10.value.elements[0].value).to eq("Value 10")

        key11 = find_message("key_11")
        expect(key11).not_to be_nil
        expect(key11.value).to be_a(Foxtail::AST::Pattern)
        expect(key11.value.elements[0].value).to eq("Value 11")

        key12 = find_message("key-12-")
        expect(key12).not_to be_nil
        expect(key12.value).to be_a(Foxtail::AST::Pattern)
        expect(key12.value.elements[0].value).to eq("Value 12")

        key13 = find_message("key_13_")
        expect(key13).not_to be_nil
        expect(key13.value).to be_a(Foxtail::AST::Pattern)
        expect(key13.value.elements[0].value).to eq("Value 13")
      end
    end
  end
end
