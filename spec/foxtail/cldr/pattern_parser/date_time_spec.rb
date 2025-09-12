# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::PatternParser::DateTime do
  subject(:parser) { Foxtail::CLDR::PatternParser::DateTime.new }

  describe "#parse" do
    context "with empty or nil patterns" do
      it "returns empty array for nil" do
        expect(parser.parse(nil)).to eq([])
      end

      it "returns empty array for empty string" do
        expect(parser.parse("")).to eq([])
      end
    end

    context "with simple field patterns" do
      it "parses year patterns" do
        tokens = parser.parse("yyyy")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::FieldToken)
        expect(tokens.first.value).to eq("yyyy")
        expect(tokens.first.field_type).to eq(:year)
        expect(tokens.first.field_length).to eq(4)
      end

      it "parses month patterns" do
        tokens = parser.parse("MMMM")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::FieldToken)
        expect(tokens.first.value).to eq("MMMM")
        expect(tokens.first.field_type).to eq(:month)
        expect(tokens.first.field_length).to eq(4)
      end

      it "parses day patterns" do
        tokens = parser.parse("dd")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::FieldToken)
        expect(tokens.first.value).to eq("dd")
        expect(tokens.first.field_type).to eq(:day)
        expect(tokens.first.field_length).to eq(2)
      end

      it "parses weekday patterns" do
        tokens = parser.parse("EEEE")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::FieldToken)
        expect(tokens.first.value).to eq("EEEE")
        expect(tokens.first.field_type).to eq(:weekday)
        expect(tokens.first.field_length).to eq(4)
      end

      it "parses hour patterns" do
        tokens = parser.parse("HH")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::FieldToken)
        expect(tokens.first.value).to eq("HH")
        expect(tokens.first.field_type).to eq(:hour)
        expect(tokens.first.field_length).to eq(2)
      end

      it "parses AM/PM patterns" do
        tokens = parser.parse("a")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::FieldToken)
        expect(tokens.first.value).to eq("a")
        expect(tokens.first.field_type).to eq(:am_pm)
        expect(tokens.first.field_length).to eq(1)
      end
    end

    context "with literal text" do
      it "parses simple literals" do
        tokens = parser.parse("Date:")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::LiteralToken)
        expect(tokens.first.value).to eq("Date:")
      end

      it "combines consecutive literal characters" do
        tokens = parser.parse("Date: Time:")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::LiteralToken)
        expect(tokens.first.value).to eq("Date: Time:")
      end
    end

    context "with quoted literals" do
      it "parses simple quoted text" do
        tokens = parser.parse("'Today is'")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::QuotedToken)
        expect(tokens.first.value).to eq("'Today is'")
        expect(tokens.first.literal_text).to eq("Today is")
      end

      it "handles escaped quotes" do
        tokens = parser.parse("'Today''s date'")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::QuotedToken)
        expect(tokens.first.literal_text).to eq("Today's date")
      end

      it "handles empty quoted strings" do
        tokens = parser.parse("''")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::QuotedToken)
        expect(tokens.first.literal_text).to eq("")
      end
    end

    context "with mixed patterns" do
      it "parses complex date pattern" do
        tokens = parser.parse("EEEE, MMMM d, yyyy")
        expect(tokens).to have_attributes(size: 7)

        expect(tokens[0]).to be_a(described_class::FieldToken)
        expect(tokens[0].value).to eq("EEEE")

        expect(tokens[1]).to be_a(described_class::LiteralToken)
        expect(tokens[1].value).to eq(", ")

        expect(tokens[2]).to be_a(described_class::FieldToken)
        expect(tokens[2].value).to eq("MMMM")

        expect(tokens[3]).to be_a(described_class::LiteralToken)
        expect(tokens[3].value).to eq(" ")

        expect(tokens[4]).to be_a(described_class::FieldToken)
        expect(tokens[4].value).to eq("d")

        expect(tokens[5]).to be_a(described_class::LiteralToken)
        expect(tokens[5].value).to eq(", ")

        expect(tokens[6]).to be_a(described_class::FieldToken)
        expect(tokens[6].value).to eq("yyyy")
      end

      it "parses pattern with quoted literals" do
        tokens = parser.parse("EEEE 'at' HH:mm")
        expect(tokens).to have_attributes(size: 7)

        expect(tokens[0]).to be_a(described_class::FieldToken)
        expect(tokens[0].value).to eq("EEEE")

        expect(tokens[1]).to be_a(described_class::LiteralToken)
        expect(tokens[1].value).to eq(" ")

        expect(tokens[2]).to be_a(described_class::QuotedToken)
        expect(tokens[2].value).to eq("'at'")
        expect(tokens[2].literal_text).to eq("at")

        expect(tokens[3]).to be_a(described_class::LiteralToken)
        expect(tokens[3].value).to eq(" ")

        expect(tokens[4]).to be_a(described_class::FieldToken)
        expect(tokens[4].value).to eq("HH")

        expect(tokens[5]).to be_a(described_class::LiteralToken)
        expect(tokens[5].value).to eq(":")

        expect(tokens[6]).to be_a(described_class::FieldToken)
        expect(tokens[6].value).to eq("mm")
      end

      it "parses pattern with potential ambiguous tokens" do
        # This was the challenging case: "Date: dd/MM/yyyy Time: HH:mm"
        # The 'a' in "Date:" should not be parsed as AM/PM
        tokens = parser.parse("Date: dd/MM/yyyy Time: HH:mm")

        # Should parse as: ["Date: ", "dd", "/", "MM", "/", "yyyy", " Time: ", "HH", ":", "mm"]
        expect(tokens[0]).to be_a(described_class::LiteralToken)
        expect(tokens[0].value).to eq("Date: ")

        expect(tokens[1]).to be_a(described_class::FieldToken)
        expect(tokens[1].value).to eq("dd")
      end

      it "parses Japanese pattern correctly" do
        # The challenging case: "yyyy年MMMMd日(EEEE)"
        # The 'd' should be parsed as day field even when surrounded by Japanese characters
        tokens = parser.parse("yyyy年MMMMd日(EEEE)")

        expect(tokens[0]).to be_a(described_class::FieldToken)
        expect(tokens[0].value).to eq("yyyy")

        expect(tokens[1]).to be_a(described_class::LiteralToken)
        expect(tokens[1].value).to eq("年")

        expect(tokens[2]).to be_a(described_class::FieldToken)
        expect(tokens[2].value).to eq("MMMM")

        expect(tokens[3]).to be_a(described_class::FieldToken)
        expect(tokens[3].value).to eq("d")

        expect(tokens[4]).to be_a(described_class::LiteralToken)
        expect(tokens[4].value).to eq("日(")

        expect(tokens[5]).to be_a(described_class::FieldToken)
        expect(tokens[5].value).to eq("EEEE")

        expect(tokens[6]).to be_a(described_class::LiteralToken)
        expect(tokens[6].value).to eq(")")
      end
    end

    context "with edge cases" do
      it "handles standalone AM/PM correctly" do
        tokens = parser.parse("a")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::FieldToken)
        expect(tokens.first.value).to eq("a")
      end

      it "distinguishes AM/PM from letter in word" do
        # This should treat 'a' as part of the word, not as AM/PM
        tokens = parser.parse("Date")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::LiteralToken)
        expect(tokens.first.value).to eq("Date")
      end

      it "handles multiple consecutive field patterns" do
        tokens = parser.parse("yyyyMMdd")
        expect(tokens).to have_attributes(size: 3)

        expect(tokens[0]).to be_a(described_class::FieldToken)
        expect(tokens[0].value).to eq("yyyy")

        expect(tokens[1]).to be_a(described_class::FieldToken)
        expect(tokens[1].value).to eq("MM")

        expect(tokens[2]).to be_a(described_class::FieldToken)
        expect(tokens[2].value).to eq("dd")
      end
    end
  end

  describe "Token classes" do
    describe "Token equality" do
      it "considers tokens equal if same class and value" do
        token1 = described_class::FieldToken.new("yyyy")
        token2 = described_class::FieldToken.new("yyyy")
        expect(token1).to eq(token2)
      end

      it "considers tokens different if different class" do
        field_token = described_class::FieldToken.new("yyyy")
        literal_token = described_class::LiteralToken.new("yyyy")
        expect(field_token).not_to eq(literal_token)
      end
    end

    describe "Token string representation" do
      it "returns value as string" do
        token = described_class::FieldToken.new("yyyy")
        expect(token.to_s).to eq("yyyy")
      end
    end
  end
end
