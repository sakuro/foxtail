# frozen_string_literal: true

require "fileutils"

RSpec.describe Foxtail::CLDR::Repository::NumberFormats do
  describe "#initialize" do
    it "loads formats for supported locale" do
      formats = Foxtail::CLDR::Repository::NumberFormats.new(locale("en"))
      expect(formats).to be_instance_of(Foxtail::CLDR::Repository::NumberFormats)
    end

    it "raises DataNotAvailable for unsupported locale" do
      expect {
        Foxtail::CLDR::Repository::NumberFormats.new(locale("nonexistent"))
      }.to raise_error(Foxtail::CLDR::Repository::DataNotAvailable)
    end
  end

  describe "number symbols" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::NumberFormats.new(locale("en")) }

      it "returns decimal symbol" do
        expect(formats.decimal_symbol).to eq(".")
      end

      it "returns group symbol" do
        expect(formats.group_symbol).to eq(",")
      end

      it "returns minus sign" do
        expect(formats.minus_sign).to eq("-")
      end

      it "returns plus sign" do
        expect(formats.plus_sign).to eq("+")
      end

      it "returns percent sign" do
        expect(formats.percent_sign).to eq("%")
      end

      it "returns per mille sign" do
        expect(formats.per_mille_sign).to eq("‰")
      end

      it "returns infinity symbol" do
        expect(formats.infinity_symbol).to eq("∞")
      end

      it "returns NaN symbol" do
        expect(formats.nan_symbol).to eq("NaN")
      end
    end

    context "with French locale" do
      let(:formats) { Foxtail::CLDR::Repository::NumberFormats.new(locale("fr")) }

      it "returns decimal symbol" do
        expect(formats.decimal_symbol).to eq(",")
      end

      it "returns group symbol" do
        expect(formats.group_symbol).to eq("\u202F")
      end
    end

    context "with Japanese locale" do
      let(:formats) { Foxtail::CLDR::Repository::NumberFormats.new(locale("ja")) }

      it "returns decimal symbol" do
        expect(formats.decimal_symbol).to eq(".")
      end

      it "returns group symbol" do
        expect(formats.group_symbol).to eq(",")
      end
    end
  end

  describe "number patterns" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::NumberFormats.new(locale("en")) }

      it "returns decimal pattern" do
        expect(formats.decimal_pattern).to eq("#,##0.###")
      end

      it "returns percent pattern" do
        expect(formats.percent_pattern).to eq("#,##0%")
      end

      it "returns currency pattern" do
        expect(formats.currency_pattern).to eq("¤#,##0.00")
      end

      it "returns scientific pattern" do
        expect(formats.scientific_pattern).to eq("#E0")
      end
    end
  end

  describe "compact number patterns" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::NumberFormats.new(locale("en")) }

      it "returns compact pattern for thousands" do
        pattern = formats.compact_pattern(1000, "short")
        expect(pattern).to eq("0K")
      end

      it "returns compact pattern for millions" do
        pattern = formats.compact_pattern(1_000_000, "short")
        expect(pattern).to eq("0M")
      end

      it "returns compact pattern for billions" do
        pattern = formats.compact_pattern(1_000_000_000, "short")
        expect(pattern).to eq("0B")
      end

      it "returns compact pattern for long style thousands" do
        pattern = formats.compact_pattern(1000, "long")
        expect(pattern).to eq("0 thousand")
      end

      it "returns all compact patterns for a style" do
        patterns = formats.compact_patterns("short")
        expect(patterns).to be_a(Hash)
        expect(patterns.keys).to include("1000", "10000", "100000", "1000000")
      end

      it "returns compact decimal significant digits" do
        result = formats.compact_decimal_significant_digits
        expect(result).to be_a(Hash)
        expect(result).to include(:minimum, :maximum)
        expect(result[:minimum]).to be_a(Integer)
        expect(result[:maximum]).to be_a(Integer)
      end
    end

    context "with Japanese locale" do
      let(:formats) { Foxtail::CLDR::Repository::NumberFormats.new(locale("ja")) }

      it "returns compact pattern for ten thousands (万)" do
        pattern = formats.compact_pattern(10000, "short")
        expect(pattern).to eq("0万")
      end

      it "returns compact pattern for hundred millions (億)" do
        pattern = formats.compact_pattern(100_000_000, "short")
        expect(pattern).to eq("0億")
      end
    end
  end
end
