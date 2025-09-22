# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Function::JavaScript do
  describe "NumberFormat" do
    subject(:formatter) { Foxtail::Function::JavaScript::NumberFormat.new(locale:) }

    let(:locale) { Locale::Tag.parse("en-US") }

    describe "#call" do
      it "formats basic numbers" do
        result = formatter.call(1234.56)
        expect(result).to eq("1,234.56")
      end

      it "formats currency" do
        currency_formatter = Foxtail::Function::JavaScript::NumberFormat.new(locale:, style: "currency", currency: "USD")
        result = currency_formatter.call(1234.56)
        expect(result).to eq("$1,234.56")
      end

      it "formats percentages" do
        percent_formatter = Foxtail::Function::JavaScript::NumberFormat.new(locale:, style: "percent")
        result = percent_formatter.call(0.1234)
        expect(result).to eq("12%")
      end

      it "handles compact notation" do
        compact_formatter = Foxtail::Function::JavaScript::NumberFormat.new(locale:, notation: "compact")
        result = compact_formatter.call(1_234_567)
        expect(result).to eq("1.2M")
      end
    end
  end

  describe "DateTimeFormat" do
    subject(:formatter) { Foxtail::Function::JavaScript::DateTimeFormat.new(locale:) }

    let(:locale) { Locale::Tag.parse("en-US") }

    describe "#call" do
      let(:time) { Time.new(2023, 12, 25, 14, 30, 0) }

      it "formats basic datetime" do
        result = formatter.call(time)
        expect(result).to include("2023")
        expect(result).to include("25")
      end

      it "formats with dateStyle" do
        full_formatter = Foxtail::Function::JavaScript::DateTimeFormat.new(locale:, dateStyle: "full")
        result = full_formatter.call(time)
        expect(result).to include("December")
        expect(result).to include("2023")
      end

      it "formats with timeStyle" do
        time_formatter = Foxtail::Function::JavaScript::DateTimeFormat.new(locale:, timeStyle: "short")
        result = time_formatter.call(time)
        expect(result).to include("2:30")
      end

      it "handles Date objects" do
        date = Date.new(2023, 12, 25)
        result = formatter.call(date)
        expect(result).to include("2023")
        expect(result).to include("25")
      end

      it "handles string timestamps" do
        result = formatter.call("2023-12-25T14:30:00Z")
        expect(result).to include("2023")
        expect(result).to include("25")
      end

      it "raises error for invalid time values" do
        expect {
          formatter.call("invalid date")
        }.to raise_error(ArgumentError)
      end
    end

    describe "#convert_to_timestamp" do
      let(:time) { Time.new(2023, 12, 25, 14, 30, 0) }

      it "converts Time objects with high precision" do
        timestamp = formatter.__send__(:convert_to_timestamp, time)
        expected = (time.tv_sec * 1000) + (time.tv_nsec / 1_000_000)
        expect(timestamp).to eq(expected)
      end

      it "converts Date objects" do
        date = Date.new(2023, 12, 25)
        timestamp = formatter.__send__(:convert_to_timestamp, date)
        expect(timestamp).to be_a(Integer)
        expect(timestamp).to be > 0
      end

      it "handles numeric timestamps" do
        timestamp = formatter.__send__(:convert_to_timestamp, 1_703_512_200_000)
        expect(timestamp).to eq(1_703_512_200_000)
      end

      it "parses string dates" do
        timestamp = formatter.__send__(:convert_to_timestamp, "2023-12-25T14:30:00Z")
        expect(timestamp).to be_a(Integer)
        expect(timestamp).to be > 0
      end

      it "raises error for invalid types" do
        expect {
          formatter.__send__(:convert_to_timestamp, {})
        }.to raise_error(ArgumentError, "Cannot convert Hash to timestamp")
      end
    end
  end
end
