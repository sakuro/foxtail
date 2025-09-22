# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Function::Backend::JavaScript do
  # Force Node.js runtime for consistent test behavior
  subject(:backend) { Foxtail::Function::Backend::JavaScript.new }

  before(:all) do
    # Check if Node.js is available
    node_available = system("node --version > /dev/null 2>&1")
    skip "Node.js not available" unless node_available

    # Force ExecJS to use Node.js runtime
    @original_runtime = ExecJS.runtime
    ExecJS.runtime = ExecJS::Runtimes::Node
  rescue ExecJS::RuntimeUnavailable
    skip "Node.js runtime not available for ExecJS"
  end

  after(:all) do
    # Restore original runtime
    ExecJS.runtime = @original_runtime if defined?(@original_runtime)
  end

  describe "#available?" do
    context "when ExecJS runtime is available" do
      it "returns true" do
        expect(backend.available?).to be true
      end
    end

    context "when ExecJS runtime is not available" do
      before do
        allow(ExecJS).to receive(:compile).and_raise(ExecJS::RuntimeUnavailable)
      end

      it "returns false" do
        expect(backend.available?).to be false
      end
    end
  end

  describe "#name" do
    it "includes runtime information when available" do
      if backend.available?
        expect(backend.name).to match(/JavaScript \(.+\)/)
      else
        expect(backend.name).to eq("JavaScript (unavailable)")
      end
    end
  end

  describe "#call" do
    before do
      skip "ExecJS runtime not available" unless backend.available?
    end

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

      it "handles compact notation" do
        result = backend.call("NUMBER", 1_234_567, locale:, notation: "compact")
        expect(result).to eq("1.2M")
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
        expect(result).to include("2:30")
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

      it "handles string timestamps" do
        result = backend.call("DATETIME", "2023-12-25T14:30:00Z", locale:)
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

      it "handles invalid time values gracefully" do
        expect {
          backend.call("DATETIME", "invalid date", locale:)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#convert_to_timestamp" do
    let(:time) { Time.new(2023, 12, 25, 14, 30, 0) }

    it "converts Time objects with high precision" do
      timestamp = backend.__send__(:convert_to_timestamp, time)
      expected = (time.tv_sec * 1000) + (time.tv_nsec / 1_000_000)
      expect(timestamp).to eq(expected)
    end

    it "converts DateTime objects" do
      datetime = Time.new(2023, 12, 25, 14, 30, 0)
      timestamp = backend.__send__(:convert_to_timestamp, datetime)
      expect(timestamp).to be_a(Integer)
      expect(timestamp).to be > 0
    end

    it "converts Date objects" do
      date = Date.new(2023, 12, 25)
      timestamp = backend.__send__(:convert_to_timestamp, date)
      expect(timestamp).to be_a(Integer)
      expect(timestamp).to be > 0
    end

    it "handles numeric timestamps" do
      timestamp = backend.__send__(:convert_to_timestamp, 1_703_512_200_000)
      expect(timestamp).to eq(1_703_512_200_000)
    end

    it "parses string dates" do
      timestamp = backend.__send__(:convert_to_timestamp, "2023-12-25T14:30:00Z")
      expect(timestamp).to be_a(Integer)
      expect(timestamp).to be > 0
    end

    it "raises error for invalid types" do
      expect {
        backend.__send__(:convert_to_timestamp, {})
      }.to raise_error(ArgumentError, /Cannot convert/)
    end
  end

  describe "options conversion" do
    describe "#convert_number_options" do
      it "converts symbol keys to strings" do
        options = {style: "currency", currency: "USD", minimumFractionDigits: 2}
        result = backend.__send__(:convert_number_options, options)

        expect(result).to eq({
          "style" => "currency",
          "currency" => "USD",
          "minimumFractionDigits" => 2
        })
      end

      it "handles boolean values" do
        options = {useGrouping: true}
        result = backend.__send__(:convert_number_options, options)
        expect(result["useGrouping"]).to be true
      end
    end

    describe "#convert_datetime_options" do
      it "converts symbol keys to strings" do
        options = {dateStyle: "full", timeStyle: "short", hour12: true}
        result = backend.__send__(:convert_datetime_options, options)

        expect(result).to eq({
          "dateStyle" => "full",
          "timeStyle" => "short",
          "hour12" => true
        })
      end
    end
  end
end
