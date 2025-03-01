# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with empty pattern in messages", ftl_fixture: "structure/message_with_empty_pattern" do
      it "correctly handles messages with empty patterns" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify the ResourceComment
        expect(result.body[0]).to be_a(Foxtail::AST::ResourceComment)
        expect(result.body[0].content).to include("BE CAREFUL WHEN EDITING THIS FILE")

        # Verify that messages without attributes (key1, key2, key5) are Junk
        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(3)

        # Verify that each Junk has an annotation with "Expected message to have a value or attributes"
        junk_entries.each do |junk|
          expect(junk.annotations).not_to be_empty
          expect(junk.annotations.any? {|a| a.message.include?("Expected message") && a.message.include?("to have a value or attributes") }).to be true
        end

        # Verify that messages with attributes (key3, key4) are valid and have null value
        message_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Message) }
        expect(message_entries.size).to eq(2)

        message_entries.each do |message|
          expect(message.value).to be_nil
          expect(message.attributes.size).to eq(1)
          expect(message.attributes[0].id.name).to eq("attr")
          expect(message.attributes[0].value.elements[0].value).to eq("Attr")
        end
      end
    end
  end
end
