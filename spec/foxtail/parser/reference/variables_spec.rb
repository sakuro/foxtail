# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with variables", ftl_fixture: "reference/variables" do
      it "parses variable references correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Test valid variable references (key01-key04)
        (1..4).each do |i|
          key = "key%02d" % i
          message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == key }
          expect(message).not_to be_nil, "Message #{key} not found"
          expect(message.value).to be_a(Foxtail::AST::Pattern)
          expect(message.value.elements.size).to eq(1)
          expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)
          expect(message.value.elements[0].expression).to be_a(Foxtail::AST::VariableReference)
          expect(message.value.elements[0].expression.id.name).to eq("var")
        end

        # Test error cases
        # Verify the GroupComment
        group_comment = result.body.find {|entry| entry.is_a?(Foxtail::AST::GroupComment) }
        expect(group_comment).not_to be_nil
        expect(group_comment.content).to eq("Errors")

        # Error case 1: Missing variable identifier
        err01_comment = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Comment) && entry.content.include?("Missing variable identifier")
        }
        expect(err01_comment).not_to be_nil

        err01_junk = result.body[result.body.index(err01_comment) + 1]
        expect(err01_junk).to be_a(Foxtail::AST::Junk)
        expect(err01_junk.content).to eq("err01 = {$}\n")

        # Error case 2: Double $ symbol
        err02_comment = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Comment) && entry.content.include?("Double $$")
        }
        expect(err02_comment).not_to be_nil

        err02_junk = result.body[result.body.index(err02_comment) + 1]
        expect(err02_junk).to be_a(Foxtail::AST::Junk)
        expect(err02_junk.content).to eq("err02 = {$$var}\n")

        # Error case 3: Invalid first character in identifier
        err03_comment = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Comment) && entry.content.include?("Invalid first char")
        }
        expect(err03_comment).not_to be_nil

        err03_junk = result.body[result.body.index(err03_comment) + 1]
        expect(err03_junk).to be_a(Foxtail::AST::Junk)
        expect(err03_junk.content).to eq("err03 = {$-var}\n")
      end
    end
  end
end
