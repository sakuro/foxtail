# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with tab characters", ftl_fixture: "reference/tab" do
      it "parses tab characters correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Define tab character for better readability
        tab = "\t"

        # Verify the first message (tab after = is part of the value)
        message1 = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key01" }
        expect(message1).not_to be_nil
        expect(message1.value.elements[0].value).to eq("#{tab}Value 01")
        expect(message1.comment).not_to be_nil
        expect(message1.comment.content).to eq("OK (tab after = is part of the value)")

        # Verify the comment for the second message
        comment2 = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Comment) && entry.content == "Error (tab before =)"
        }
        expect(comment2).not_to be_nil

        # Verify the junk for the second message
        junk2 = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Junk) && entry.content.include?("key02\t= Value 02")
        }
        expect(junk2).not_to be_nil

        # Verify the comment for the third message
        comment3 = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Comment) && entry.content == "Error (tab is not a valid indent)"
        }
        expect(comment3).not_to be_nil

        # Verify the junk for the third message
        junk3 = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Junk) && entry.content.include?("key03 =\n\tThis line isn't properly indented.")
        }
        expect(junk3).not_to be_nil

        # Verify the fourth message (partial error with tab indentation)
        message4 = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key04" }
        expect(message4).not_to be_nil

        # The actual value has a trailing comma, so we use include instead of eq
        expect(message4.value.elements[0].value).to include("This line is indented by 4 spaces")

        # Verify the junk for the fourth message
        junk4 = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Junk) && entry.content.include?("\twhereas this line by 1 tab.")
        }
        expect(junk4).not_to be_nil

        # Verify the fifth message (value is a single tab)
        message5 = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key05" }
        expect(message5).not_to be_nil
        expect(message5.value.elements[0].value).to eq(tab)

        # Verify the sixth message (attribute value is two tabs)
        message6 = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key06" }
        expect(message6).not_to be_nil
        expect(message6.value).to be_nil
        expect(message6.attributes.size).to eq(1)
        expect(message6.attributes[0].id.name).to eq("attr")
        expect(message6.attributes[0].value.elements[0].value).to eq("#{tab}#{tab}")
      end
    end
  end
end
