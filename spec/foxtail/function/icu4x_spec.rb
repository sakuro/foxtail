# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Function::Icu4xBackend do
  describe "NumberFormat" do
    subject(:formatter) { Foxtail::Function::Icu4xBackend::NumberFormat.new(locale:) }

    let(:locale) { Locale::Tag.parse("en-US") }

    describe "#call" do
      it "formats basic numbers" do
        result = formatter.call(1234.56)
        expect(result).to eq("1,234.56")
      end

      it "formats currency" do
        currency_formatter = Foxtail::Function::Icu4xBackend::NumberFormat.new(locale:, style: :currency, currency: "USD")
        result = currency_formatter.call(1234.56)
        expect(result).to eq("$1,234.56")
      end

      it "formats percentages" do
        percent_formatter = Foxtail::Function::Icu4xBackend::NumberFormat.new(locale:, style: :percent)
        result = percent_formatter.call(0.1234)
        # ICU4X preserves more precision than JS Intl
        expect(result).to match(/12(\.34)?%/)
      end

      it "handles compact notation" do
        skip "not yet supported by icu4x gem"
        compact_formatter = Foxtail::Function::Icu4xBackend::NumberFormat.new(locale:, notation: "compact")
        result = compact_formatter.call(1_234_567)
        expect(result).to eq("1.2M")
      end

      it "handles minimumFractionDigits option" do
        formatter = Foxtail::Function::Icu4xBackend::NumberFormat.new(locale:, minimumFractionDigits: 3)
        result = formatter.call(1234.5)
        expect(result).to eq("1,234.500")
      end

      it "handles maximumFractionDigits option" do
        formatter = Foxtail::Function::Icu4xBackend::NumberFormat.new(locale:, maximumFractionDigits: 1)
        result = formatter.call(1234.567)
        expect(result).to eq("1,234.6")
      end

      it "handles useGrouping: false option" do
        formatter = Foxtail::Function::Icu4xBackend::NumberFormat.new(locale:, useGrouping: false)
        result = formatter.call(1_234_567)
        expect(result).to eq("1234567")
      end
    end
  end

  describe "DateTimeFormat" do
    let(:locale) { Locale::Tag.parse("en-US") }
    let(:time) { Time.new(2023, 12, 25, 14, 30, 0) }

    describe "#call" do
      it "formats with dateStyle: :medium" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:, dateStyle: :medium)
        result = formatter.call(time)
        expect(result).to include("Dec")
        expect(result).to include("2023")
      end

      it "formats with dateStyle: :full" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:, dateStyle: :full)
        result = formatter.call(time)
        expect(result).to include("December")
        expect(result).to include("2023")
      end

      it "formats with timeStyle: :short" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:, timeStyle: :short)
        result = formatter.call(time)
        # Time formatting depends on system timezone; just verify format structure
        expect(result).to match(/\d{1,2}:\d{2}/)
      end

      it "formats with both dateStyle and timeStyle" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:, dateStyle: :short, timeStyle: :short)
        result = formatter.call(time)
        expect(result).to include("12/")
        # Time formatting depends on system timezone; just verify format structure
        expect(result).to match(/\d{1,2}:\d{2}/)
      end

      it "handles Date objects" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:, dateStyle: :medium)
        date = Date.new(2023, 12, 25)
        result = formatter.call(date)
        expect(result).to include("Dec")
        expect(result).to include("2023")
      end

      it "handles string timestamps" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:, dateStyle: :medium)
        result = formatter.call("2023-12-25T14:30:00Z")
        expect(result).to include("Dec")
        expect(result).to include("2023")
      end

      it "handles integer timestamps" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:, dateStyle: :medium)
        result = formatter.call(1_703_512_200)
        expect(result).to include("Dec")
        expect(result).to include("2023")
      end

      it "raises error for invalid time values" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:, dateStyle: :medium)
        expect {
          formatter.call({})
        }.to raise_error(ArgumentError, "Cannot convert Hash to Time")
      end

      it "uses medium date_style as default when no style is specified" do
        formatter = Foxtail::Function::Icu4xBackend::DateTimeFormat.new(locale:)
        result = formatter.call(time)
        # Should include Dec and 2023 for medium format
        expect(result).to include("Dec")
        expect(result).to include("2023")
      end
    end
  end

  describe "locale handling" do
    it "accepts Locale::Tag objects" do
      locale = Locale::Tag.parse("ja-JP")
      formatter = Foxtail::Function::Icu4xBackend::NumberFormat.new(locale:)
      result = formatter.call(1234.56)
      expect(result).to eq("1,234.56")
    end

    it "accepts string locales" do
      formatter = Foxtail::Function::Icu4xBackend::NumberFormat.new(locale: "de-DE")
      result = formatter.call(1234.56)
      expect(result).to eq("1.234,56")
    end
  end
end
