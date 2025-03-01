# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with junk", ftl_fixture: "structure/junk" do
      it "parses junk entries correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains 9 entries (8 Junk and 1 Message)
        expect(result.body.size).to eq(9)
        expect(result.body.count {|entry| entry.is_a?(Foxtail::AST::Junk) }).to eq(8)
        expect(result.body.count {|entry| entry.is_a?(Foxtail::AST::Message) }).to eq(1)

        # Verify the first Junk entry
        junk1 = result.body[0]
        expect(junk1).to be_a(Foxtail::AST::Junk)
        expect(junk1.content).to eq("err01 = {1xx}\n")
        expect(junk1.annotations.size).to eq(1)
        expect(junk1.annotations[0].code).to eq("E0003")
        expect(junk1.annotations[0].message).to include("Expected token: }")

        # Verify the second Junk entry
        junk2 = result.body[1]
        expect(junk2).to be_a(Foxtail::AST::Junk)
        expect(junk2.content).to eq("err02 = {1xx}\n\n")
        expect(junk2.annotations.size).to eq(1)
        expect(junk2.annotations[0].code).to eq("E0003")
        expect(junk2.annotations[0].message).to include("Expected token: }")

        # Verify the valid Message entry
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) }
        expect(message).not_to be_nil
        expect(message.id.name).to eq("key08")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Value")

        # Verify the last Junk entry
        last_junk = result.body.last
        expect(last_junk).to be_a(Foxtail::AST::Junk)
        expect(last_junk.content).to eq("err09 = {\n")
        expect(last_junk.annotations.size).to eq(1)
        expect(last_junk.annotations[0].code).to eq("E0028")
        expect(last_junk.annotations[0].message).to include("Expected an expression")
      end
    end
  end
end
