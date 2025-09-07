# frozen_string_literal: true

require "locale"
require "time"

RSpec.describe Foxtail::Functions::DateTimeFormatter do
  subject(:formatter) { Foxtail::Functions::DateTimeFormatter.new }

  let(:test_time) { Time.new(2023, 6, 15, 14, 30, 45) }

  describe "#call" do
    context "with locale options" do
      it "formats with English locale" do
        result = formatter.call(test_time, locale: locale("en"), dateStyle: "full")
        expect(result).to eq("Thursday, June 15, 2023")
      end

      it "formats with Japanese locale" do
        result = formatter.call(test_time, locale: locale("ja"), dateStyle: "full")
        expect(result).to eq("2023年6月15日木曜日")
      end

      it "formats month names in Japanese" do
        result = formatter.call(test_time, locale: locale("ja"), month: "long")
        expect(result).to eq("6月")
      end

      it "formats weekday names in Japanese" do
        result = formatter.call(test_time, locale: locale("ja"), weekday: "long")
        expect(result).to eq("木曜日")
      end

      it "raises CLDR::DataNotAvailable for unknown locales" do
        expect {
          formatter.call(test_time, locale: locale("unknown"), month: "long")
        }.to raise_error(Foxtail::CLDR::DataNotAvailable)
      end
    end

    context "with different date/time styles" do
      let(:en_locale) { locale("en") }

      it "formats with dateStyle medium" do
        result = formatter.call(test_time, locale: en_locale, dateStyle: "medium")
        expect(result).to eq("Jun 15, 2023")
      end

      it "formats with dateStyle full" do
        result = formatter.call(test_time, locale: en_locale, dateStyle: "full")
        expect(result).to eq("Thursday, June 15, 2023")
      end

      it "formats with timeStyle short" do
        result = formatter.call(test_time, locale: en_locale, timeStyle: "short")
        # NOTE: CLDR uses \u202F (Narrow No-Break Space) between time and AM/PM
        expect(result).to eq("2:30\u202FPM")
      end

      it "combines dateStyle and timeStyle" do
        result = formatter.call(test_time, locale: en_locale, dateStyle: "medium", timeStyle: "short")
        # NOTE: CLDR uses \u202F (Narrow No-Break Space) between time and AM/PM
        expect(result).to eq("Jun 15, 2023 2:30\u202FPM")
      end
    end

    context "with invalid input" do
      it "raises ArgumentError for invalid date strings" do
        expect {
          formatter.call("not a date", locale: locale("en"))
        }.to raise_error(ArgumentError)
      end

      it "raises ArgumentError for unparseable date strings" do
        expect {
          formatter.call("2023-13-99", locale: locale("en"))
        }.to raise_error(ArgumentError)
      end
    end
  end
end
