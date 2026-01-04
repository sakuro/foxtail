# frozen_string_literal: true

RSpec.describe Foxtail::Function do
  let(:en_locale) { ICU4X::Locale.parse("en") }
  let(:functions) { Foxtail::Function.defaults }
  let(:number_fn) { functions["NUMBER"] }
  let(:datetime_fn) { functions["DATETIME"] }

  describe ".defaults" do
    it "returns ICU4X-based function Methods" do
      expect(functions.keys).to contain_exactly("NUMBER", "DATETIME")
      expect(number_fn).to be_a(Method)
      expect(datetime_fn).to be_a(Method)
    end
  end

  describe "NUMBER function" do
    context "with numeric values" do
      it "formats integers" do
        expect(number_fn.call(42, locale: en_locale)).to eq("42")
      end

      it "formats floats" do
        expect(number_fn.call(1234.56, locale: en_locale)).to eq("1,234.56")
      end
    end

    context "with string values" do
      it "converts and formats integer strings" do
        expect(number_fn.call("42", locale: en_locale)).to eq("42")
      end

      it "converts and formats float strings" do
        expect(number_fn.call("1234.56", locale: en_locale)).to eq("1,234.56")
      end

      it "converts and formats negative number strings" do
        expect(number_fn.call("-123", locale: en_locale)).to eq("-123")
      end

      it "returns fallback for invalid strings" do
        expect(number_fn.call("not a number", locale: en_locale)).to eq("{NUMBER()}")
      end

      it "returns fallback for empty strings" do
        expect(number_fn.call("", locale: en_locale)).to eq("{NUMBER()}")
      end
    end

    context "with unsupported types" do
      it "returns fallback for nil" do
        expect(number_fn.call(nil, locale: en_locale)).to eq("{NUMBER()}")
      end

      it "returns fallback for arrays" do
        expect(number_fn.call([1, 2, 3], locale: en_locale)).to eq("{NUMBER()}")
      end
    end

    context "with formatting options" do
      it "applies minimumFractionDigits to string input" do
        expect(number_fn.call("42", locale: en_locale, minimumFractionDigits: 2)).to eq("42.00")
      end
    end
  end

  describe "DATETIME function" do
    context "with Time values" do
      it "formats Time objects" do
        # Use mid-year date to avoid timezone edge cases
        time = Time.new(2023, 6, 15)
        result = datetime_fn.call(time, locale: en_locale, dateStyle: :medium)
        expect(result).to include("2023")
      end
    end

    context "with ISO 8601 string values" do
      it "parses and formats ISO 8601 datetime strings" do
        result = datetime_fn.call("2024-06-15T10:30:00", locale: en_locale, dateStyle: :medium)
        expect(result).to include("2024")
      end

      it "parses and formats ISO 8601 datetime with timezone" do
        result = datetime_fn.call("2024-06-15T10:30:00+09:00", locale: en_locale, dateStyle: :medium)
        expect(result).to include("2024")
      end

      it "parses and formats ISO 8601 datetime with Z timezone" do
        result = datetime_fn.call("2024-06-15T10:30:00Z", locale: en_locale, dateStyle: :medium)
        expect(result).to include("2024")
      end

      it "returns fallback for date-only strings (not ISO 8601 datetime)" do
        expect(datetime_fn.call("2024-06-15", locale: en_locale)).to eq("{DATETIME()}")
      end

      it "returns fallback for invalid date strings" do
        expect(datetime_fn.call("not a date", locale: en_locale)).to eq("{DATETIME()}")
      end

      it "returns fallback for empty strings" do
        expect(datetime_fn.call("", locale: en_locale)).to eq("{DATETIME()}")
      end
    end

    context "with unsupported types" do
      it "returns fallback for nil" do
        expect(datetime_fn.call(nil, locale: en_locale)).to eq("{DATETIME()}")
      end

      it "returns fallback for numbers" do
        expect(datetime_fn.call(12345, locale: en_locale)).to eq("{DATETIME()}")
      end
    end

    context "with formatting options" do
      it "applies dateStyle to string input" do
        result = datetime_fn.call("2024-06-15T10:30:00Z", locale: en_locale, dateStyle: :long)
        expect(result).to include("June")
        expect(result).to include("2024")
      end

      it "applies timeStyle to string input" do
        result = datetime_fn.call("2024-06-15T10:30:00Z", locale: en_locale, timeStyle: :short)
        expect(result).to include(":")
      end
    end
  end
end
