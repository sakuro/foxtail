# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with astral plane characters", ftl_fixture: "reference/astral" do
      include_examples "a valid FTL resource"
      it "parses astral plane characters correctly" do
        # Verify that the body contains expected entries
        # 7 valid messages + 3 comments + 3 junk entries = 13 entries
        expect(result.body.size).to eq(13)

        # Verify the first message (face-with-tears-of-joy)
        message1 = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "face-with-tears-of-joy"
        }
        expect(message1).not_to be_nil
        expect(message1.value).to be_a(Foxtail::AST::Pattern)
        expect(message1.value.elements.size).to eq(1)
        expect(message1.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message1.value.elements[0].value).to eq("😂")

        # Verify the second message (tetragram-for-centre)
        message2 = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "tetragram-for-centre"
        }
        expect(message2).not_to be_nil
        expect(message2.value).to be_a(Foxtail::AST::Pattern)
        expect(message2.value.elements.size).to eq(1)
        expect(message2.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message2.value.elements[0].value).to eq("𝌆")

        # Verify surrogates in text
        message3 = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "surrogates-in-text"
        }
        expect(message3).not_to be_nil
        expect(message3.value.elements[0].value).to eq("\\uD83D\\uDE02")

        # Verify emoji in text
        message6 = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "emoji-in-text" }
        expect(message6).not_to be_nil
        expect(message6.value.elements[0].value).to eq("A face 😂 with tears of joy.")

        # Verify error cases are parsed as Junk
        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(3)

        # Verify junk for invalid identifier
        junk1 = junk_entries.find {|junk| junk.content.include?("err-😂 = Value") }
        expect(junk1).not_to be_nil

        # Verify junk for invalid expression
        junk2 = junk_entries.find {|junk| junk.content.include?("err-invalid-expression = { 😂 }") }
        expect(junk2).not_to be_nil

        # Verify junk for invalid variant key
        junk3 = junk_entries.find {|junk| junk.content.include?("err-invalid-variant-key = { $sel ->") }
        expect(junk3).not_to be_nil
      end
    end
  end
end
