# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Function::Backend::FoxtailIntl do
  subject(:backend) { Foxtail::Function::Backend::FoxtailIntl.new }

  describe "#available?" do
    it "returns true" do
      expect(backend.available?).to be true
    end
  end

  describe "#name" do
    it "returns backend name" do
      expect(backend.name).to eq("Foxtail-Intl (native Ruby CLDR)")
    end
  end

  describe "#call" do
    let(:locale) { Locale::Tag.parse("en-US") }

    describe "NUMBER function" do
      it "formats basic numbers" do
        result = backend.call("NUMBER", 1234.56, locale:)
        expect(result).to eq("1,234.56")
      end

      it "formats currency" do
        result = backend.call("NUMBER", 1234.56, locale:, style: "currency", currency: "USD")
        expect(result).to eq("$1,234.56")
      end

      it "formats percentages" do
        result = backend.call("NUMBER", 0.1234, locale:, style: "percent")
        expect(result).to eq("12%")
      end

      it "handles minimum fraction digits" do
        result = backend.call("NUMBER", 123, locale:, minimumFractionDigits: 2)
        expect(result).to eq("123.00")
      end

      it "handles maximum fraction digits" do
        result = backend.call("NUMBER", 123.456789, locale:, maximumFractionDigits: 2)
        expect(result).to eq("123.45") # Foxtail-Intl uses banker's rounding
      end
    end

    describe "DATETIME function" do
      let(:time) { Time.new(2023, 12, 25, 14, 30, 0) }

      it "formats basic datetime" do
        result = backend.call("DATETIME", time, locale:)
        expect(result).to include("2023")
        expect(result).to include("25")
      end

      it "formats with dateStyle" do
        result = backend.call("DATETIME", time, locale:, dateStyle: "full")
        expect(result).to include("Monday") if time.monday?
        expect(result).to include("December")
        expect(result).to include("2023")
      end

      it "formats with timeStyle" do
        result = backend.call("DATETIME", time, locale:, timeStyle: "short")
        expect(result).to include("30")
      end

      it "formats with individual components" do
        result = backend.call("DATETIME", time, locale:, year: "numeric", month: "long", day: "numeric")
        expect(result).to include("2023")
        expect(result).to include("December")
        expect(result).to include("25")
      end

      it "handles 12-hour format" do
        result = backend.call("DATETIME", time, locale:, hour: "numeric", hour12: true)
        expect(result).to include("2") # 2 PM
      end

      it "handles Date objects" do
        date = Date.new(2023, 12, 25)
        result = backend.call("DATETIME", date, locale:)
        expect(result).to include("2023")
        expect(result).to include("25")
      end

      it "handles DateTime objects" do
        datetime = Time.new(2023, 12, 25, 14, 30, 0)
        result = backend.call("DATETIME", datetime, locale:)
        expect(result).to include("2023")
        expect(result).to include("25")
      end
    end

    describe "error handling" do
      it "raises error for unknown function" do
        expect {
          backend.call("UNKNOWN", 123, locale:)
        }.to raise_error(ArgumentError, "Unknown function: UNKNOWN")
      end

      it "raises error for unknown number option" do
        expect {
          backend.call("NUMBER", 123, locale:, unknownOption: "value")
        }.to raise_error(ArgumentError, "Unknown number option: unknownOption")
      end

      it "raises error for unknown datetime option" do
        expect {
          backend.call("DATETIME", Time.now, locale:, unknownOption: "value")
        }.to raise_error(ArgumentError, "Unknown datetime option: unknownOption")
      end
    end
  end

  describe "options conversion" do
    describe "#convert_number_options" do
      it "converts symbol keys and validates types" do
        options = {style: "currency", currency: "USD", minimumFractionDigits: 2}
        result = backend.__send__(:convert_number_options, options)

        expect(result).to eq({
          style: "currency",
          currency: "USD",
          minimumFractionDigits: 2
        })
      end

      it "handles notation option" do
        options = {notation: "scientific"}
        result = backend.__send__(:convert_number_options, options)
        expect(result[:notation]).to eq("scientific")
      end
    end

    describe "#convert_datetime_options" do
      it "converts symbol keys and validates types" do
        options = {dateStyle: "full", timeStyle: "short", hour12: true}
        result = backend.__send__(:convert_datetime_options, options)

        expect(result).to eq({
          dateStyle: "full",
          timeStyle: "short",
          hour12: true
        })
      end

      it "handles individual component options" do
        options = {year: "numeric", month: "long", day: "2-digit"}
        result = backend.__send__(:convert_datetime_options, options)

        expect(result).to eq({
          year: "numeric",
          month: "long",
          day: "2-digit"
        })
      end

      it "handles timezone options" do
        options = {timeZone: "America/New_York", timeZoneName: "short"}
        result = backend.__send__(:convert_datetime_options, options)

        expect(result).to eq({
          timeZone: "America/New_York",
          timeZoneName: "short"
        })
      end
    end
  end
end
