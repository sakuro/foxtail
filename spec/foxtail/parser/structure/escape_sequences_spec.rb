# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with escape sequences", ftl_fixture: "structure/escape_sequences" do
      it "parses escape sequences correctly" do
        pending("Escape sequence handling needs to be fixed")

        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Verify that a GroupComment is included
        expect(result.body[0]).to be_a(Foxtail::AST::GroupComment)
        expect(result.body[0].content).to eq("Literal text")

        # Verify the message containing a backslash
        backslash_message = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "text-backslash-one"
        }
        expect(backslash_message).not_to be_nil
        expect(backslash_message.value.elements[0].value).to include("\\")

        # Verify quotes in string literals
        quote_message = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "quote-in-string"
        }
        expect(quote_message).not_to be_nil
        expect(quote_message.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(quote_message.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(quote_message.value.elements[0].expression.value).to include("\"")
      end
    end
  end
end
