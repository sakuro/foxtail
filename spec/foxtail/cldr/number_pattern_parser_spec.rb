# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::NumberPatternParser do
  subject(:parser) { Foxtail::CLDR::NumberPatternParser.new }

  describe "#parse" do
    context "with empty or nil patterns" do
      it "returns empty array for nil" do
        expect(parser.parse(nil)).to eq([])
      end

      it "returns empty array for empty string" do
        expect(parser.parse("")).to eq([])
      end
    end

    context "with digit patterns" do
      it "parses required zeros" do
        tokens = parser.parse("000")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::DigitToken)
        expect(tokens.first.value).to eq("000")
        expect(tokens.first.digit_count).to eq(3)
        expect(tokens.first.required?).to be(true)
        expect(tokens.first.optional?).to be(false)
      end

      it "parses optional hashes" do
        tokens = parser.parse("###")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::DigitToken)
        expect(tokens.first.value).to eq("###")
        expect(tokens.first.digit_count).to eq(3)
        expect(tokens.first.required?).to be(false)
        expect(tokens.first.optional?).to be(true)
      end

      it "parses mixed digit patterns separately" do
        tokens = parser.parse("##0")
        expect(tokens).to have_attributes(size: 2)

        expect(tokens[0]).to be_a(described_class::DigitToken)
        expect(tokens[0].value).to eq("##")
        expect(tokens[0].optional?).to be(true)

        expect(tokens[1]).to be_a(described_class::DigitToken)
        expect(tokens[1].value).to eq("0")
        expect(tokens[1].required?).to be(true)
      end
    end

    context "with special symbols" do
      it "parses decimal separator" do
        tokens = parser.parse(".")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::DecimalToken)
        expect(tokens.first.value).to eq(".")
      end

      it "parses grouping separator" do
        tokens = parser.parse(",")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::GroupToken)
        expect(tokens.first.value).to eq(",")
      end

      it "parses percent symbol" do
        tokens = parser.parse("%")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::PercentToken)
        expect(tokens.first.value).to eq("%")
      end

      it "parses per mille symbol" do
        tokens = parser.parse("‰")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::PerMilleToken)
        expect(tokens.first.value).to eq("‰")
      end

      it "parses plus sign" do
        tokens = parser.parse("+")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::PlusToken)
        expect(tokens.first.value).to eq("+")
      end

      it "parses minus sign" do
        tokens = parser.parse("-")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::MinusToken)
        expect(tokens.first.value).to eq("-")
      end

      it "parses pattern separator" do
        tokens = parser.parse(";")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::PatternSeparatorToken)
        expect(tokens.first.value).to eq(";")
      end
    end

    context "with currency symbols" do
      it "parses single currency symbol" do
        tokens = parser.parse("¤")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::CurrencyToken)
        expect(tokens.first.value).to eq("¤")
        expect(tokens.first.currency_type).to eq(:symbol)
      end

      it "parses double currency symbol" do
        tokens = parser.parse("¤¤")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::CurrencyToken)
        expect(tokens.first.value).to eq("¤¤")
        expect(tokens.first.currency_type).to eq(:code)
      end

      it "parses triple currency symbol" do
        tokens = parser.parse("¤¤¤")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::CurrencyToken)
        expect(tokens.first.value).to eq("¤¤¤")
        expect(tokens.first.currency_type).to eq(:name)
      end

      it "limits currency symbols to 3" do
        tokens = parser.parse("¤¤¤¤")
        expect(tokens).to have_attributes(size: 2)
        expect(tokens[0].value).to eq("¤¤¤")
        expect(tokens[1].value).to eq("¤")
      end
    end

    context "with scientific notation" do
      it "parses basic exponent" do
        tokens = parser.parse("E0")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::ExponentToken)
        expect(tokens.first.value).to eq("E0")
        expect(tokens.first.exponent_digits).to eq(1)
        expect(tokens.first.show_exponent_sign?).to be(false)
      end

      it "parses exponent with multiple digits" do
        tokens = parser.parse("E00")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::ExponentToken)
        expect(tokens.first.value).to eq("E00")
        expect(tokens.first.exponent_digits).to eq(2)
      end

      it "parses exponent with plus sign" do
        tokens = parser.parse("E+0")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::ExponentToken)
        expect(tokens.first.value).to eq("E+0")
        expect(tokens.first.exponent_digits).to eq(1)
        expect(tokens.first.show_exponent_sign?).to be(true)
      end

      it "parses lowercase e as exponent" do
        tokens = parser.parse("e0")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::ExponentToken)
        expect(tokens.first.value).to eq("e0")
      end

      it "does not parse E without digits as exponent" do
        tokens = parser.parse("E")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::LiteralToken)
        expect(tokens.first.value).to eq("E")
      end
    end

    context "with literal text" do
      it "parses simple literals" do
        tokens = parser.parse("Total:")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::LiteralToken)
        expect(tokens.first.value).to eq("Total:")
      end

      it "combines consecutive literal characters" do
        tokens = parser.parse("Total: Amount:")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::LiteralToken)
        expect(tokens.first.value).to eq("Total: Amount:")
      end
    end

    context "with quoted literals" do
      it "parses simple quoted text" do
        tokens = parser.parse("'Total is'")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::QuotedToken)
        expect(tokens.first.value).to eq("'Total is'")
        expect(tokens.first.literal_text).to eq("Total is")
      end

      it "handles escaped quotes" do
        tokens = parser.parse("'User''s balance'")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::QuotedToken)
        expect(tokens.first.literal_text).to eq("User's balance")
      end

      it "handles empty quoted strings" do
        tokens = parser.parse("''")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::QuotedToken)
        expect(tokens.first.literal_text).to eq("")
      end

      it "treats unclosed quotes as literals" do
        tokens = parser.parse("'unclosed")
        expect(tokens).to have_attributes(size: 1)
        expect(tokens.first).to be_a(described_class::LiteralToken)
        expect(tokens.first.value).to eq("'unclosed")
      end
    end

    context "with complete number patterns" do
      it "parses basic decimal pattern" do
        tokens = parser.parse("#,##0.00")
        expect(tokens).to have_attributes(size: 6)

        expect(tokens[0]).to be_a(described_class::DigitToken)
        expect(tokens[0].value).to eq("#")

        expect(tokens[1]).to be_a(described_class::GroupToken)
        expect(tokens[1].value).to eq(",")

        expect(tokens[2]).to be_a(described_class::DigitToken)
        expect(tokens[2].value).to eq("##")

        expect(tokens[3]).to be_a(described_class::DigitToken)
        expect(tokens[3].value).to eq("0")

        expect(tokens[4]).to be_a(described_class::DecimalToken)
        expect(tokens[4].value).to eq(".")

        expect(tokens[5]).to be_a(described_class::DigitToken)
        expect(tokens[5].value).to eq("00")
      end

      it "parses currency pattern" do
        tokens = parser.parse("¤#,##0.00")
        expect(tokens).to have_attributes(size: 7)

        expect(tokens[0]).to be_a(described_class::CurrencyToken)
        expect(tokens[0].value).to eq("¤")

        expect(tokens[1]).to be_a(described_class::DigitToken)
        expect(tokens[1].value).to eq("#")

        expect(tokens[2]).to be_a(described_class::GroupToken)

        expect(tokens[3]).to be_a(described_class::DigitToken)
        expect(tokens[3].value).to eq("##")

        expect(tokens[4]).to be_a(described_class::DigitToken)
        expect(tokens[4].value).to eq("0")

        expect(tokens[5]).to be_a(described_class::DecimalToken)

        expect(tokens[6]).to be_a(described_class::DigitToken)
        expect(tokens[6].value).to eq("00")
      end

      it "parses percent pattern" do
        tokens = parser.parse("#,##0.00%")
        expect(tokens).to have_attributes(size: 7)

        expect(tokens.last).to be_a(described_class::PercentToken)
        expect(tokens.last.value).to eq("%")
      end

      it "parses scientific notation pattern" do
        tokens = parser.parse("#.##E0")
        expect(tokens).to have_attributes(size: 4)

        expect(tokens[0]).to be_a(described_class::DigitToken)
        expect(tokens[0].value).to eq("#")

        expect(tokens[1]).to be_a(described_class::DecimalToken)

        expect(tokens[2]).to be_a(described_class::DigitToken)
        expect(tokens[2].value).to eq("##")

        expect(tokens[3]).to be_a(described_class::ExponentToken)
        expect(tokens[3].value).to eq("E0")
      end

      it "parses positive/negative pattern" do
        tokens = parser.parse("#,##0.00;(#,##0.00)")
        expect(tokens).to have_attributes(size: 15)

        # Find the separator
        separator_index = tokens.find_index {|t| t.is_a?(described_class::PatternSeparatorToken) }
        expect(separator_index).to eq(6)

        # Check negative pattern has parentheses
        expect(tokens[7]).to be_a(described_class::LiteralToken)
        expect(tokens[7].value).to eq("(")

        expect(tokens[14]).to be_a(described_class::LiteralToken)
        expect(tokens[14].value).to eq(")")
      end

      it "parses pattern with quoted literals" do
        tokens = parser.parse("'Total: '¤#,##0.00")
        expect(tokens).to have_attributes(size: 8)

        expect(tokens[0]).to be_a(described_class::QuotedToken)
        expect(tokens[0].literal_text).to eq("Total: ")

        expect(tokens[1]).to be_a(described_class::CurrencyToken)
      end
    end

    context "with edge cases" do
      it "handles multiple consecutive separators" do
        tokens = parser.parse(",,")
        expect(tokens).to have_attributes(size: 2)
        expect(tokens.all?(described_class::GroupToken)).to be(true)
      end

      it "handles mixed symbols" do
        tokens = parser.parse("+-")
        expect(tokens).to have_attributes(size: 2)
        expect(tokens[0]).to be_a(described_class::PlusToken)
        expect(tokens[1]).to be_a(described_class::MinusToken)
      end

      it "handles patterns with no digits" do
        tokens = parser.parse("¤%")
        expect(tokens).to have_attributes(size: 2)
        expect(tokens[0]).to be_a(described_class::CurrencyToken)
        expect(tokens[1]).to be_a(described_class::PercentToken)
      end
    end

    context "with real-world CLDR patterns" do
      it "parses US decimal pattern" do
        tokens = parser.parse("#,##0.###")
        # Should handle grouping and optional decimal places
        expect(tokens.size).to be > 3
        expect(tokens.any?(described_class::GroupToken)).to be(true)
        expect(tokens.any?(described_class::DecimalToken)).to be(true)
      end

      it "parses US currency pattern" do
        tokens = parser.parse("¤#,##0.00")
        expect(tokens.first).to be_a(described_class::CurrencyToken)
        expect(tokens.any?(described_class::GroupToken)).to be(true)
      end

      it "parses percent pattern with positive/negative" do
        tokens = parser.parse("#,##0%;-#,##0%")
        separator_index = tokens.find_index {|t| t.is_a?(described_class::PatternSeparatorToken) }
        expect(separator_index).not_to be_nil
        expect(tokens.count {|t| t.is_a?(described_class::PercentToken) }).to eq(2)
      end
    end
  end

  describe "Token classes" do
    describe "Token equality" do
      it "considers tokens equal if same class and value" do
        token1 = described_class::DigitToken.new("000")
        token2 = described_class::DigitToken.new("000")
        expect(token1).to eq(token2)
      end

      it "considers tokens different if different class" do
        digit_token = described_class::DigitToken.new("0")
        literal_token = described_class::LiteralToken.new("0")
        expect(digit_token).not_to eq(literal_token)
      end

      it "considers tokens different if different values" do
        token1 = described_class::DigitToken.new("0")
        token2 = described_class::DigitToken.new("00")
        expect(token1).not_to eq(token2)
      end
    end

    describe "Token string representation" do
      it "returns value as string" do
        token = described_class::DigitToken.new("000")
        expect(token.to_s).to eq("000")
      end
    end

    describe "DigitToken methods" do
      it "correctly identifies required vs optional digits" do
        required_token = described_class::DigitToken.new("000")
        optional_token = described_class::DigitToken.new("###")

        expect(required_token.required?).to be(true)
        expect(required_token.optional?).to be(false)

        expect(optional_token.required?).to be(false)
        expect(optional_token.optional?).to be(true)
      end

      it "correctly counts digits" do
        token = described_class::DigitToken.new("0000")
        expect(token.digit_count).to eq(4)
      end
    end

    describe "CurrencyToken methods" do
      it "correctly identifies currency types" do
        symbol_token = described_class::CurrencyToken.new("¤")
        code_token = described_class::CurrencyToken.new("¤¤")
        name_token = described_class::CurrencyToken.new("¤¤¤")

        expect(symbol_token.currency_type).to eq(:symbol)
        expect(code_token.currency_type).to eq(:code)
        expect(name_token.currency_type).to eq(:name)
      end
    end

    describe "ExponentToken methods" do
      it "correctly counts exponent digits" do
        token1 = described_class::ExponentToken.new("E0")
        token2 = described_class::ExponentToken.new("E00")
        token3 = described_class::ExponentToken.new("E+000")

        expect(token1.exponent_digits).to eq(1)
        expect(token2.exponent_digits).to eq(2)
        expect(token3.exponent_digits).to eq(3)
      end

      it "correctly identifies exponent sign display" do
        token_without_sign = described_class::ExponentToken.new("E0")
        token_with_sign = described_class::ExponentToken.new("E+0")

        expect(token_without_sign.show_exponent_sign?).to be(false)
        expect(token_with_sign.show_exponent_sign?).to be(true)
      end
    end

    describe "QuotedToken methods" do
      it "correctly extracts literal text" do
        token = described_class::QuotedToken.new("'Hello World'")
        expect(token.literal_text).to eq("Hello World")
      end

      it "handles escaped quotes in literal text" do
        token = described_class::QuotedToken.new("'Don''t worry'")
        expect(token.literal_text).to eq("Don't worry")
      end
    end
  end
end
