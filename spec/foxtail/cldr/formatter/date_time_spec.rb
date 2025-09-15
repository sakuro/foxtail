# frozen_string_literal: true

require "time"

RSpec.describe Foxtail::CLDR::Formatter::DateTime do
  subject(:formatter) { Foxtail::CLDR::Formatter::DateTime.new }

  let(:test_time) { Time.utc(2023, 6, 15, 14, 30, 45) }

  # Stub timezone detection to return JST for consistent test results
  before do
    allow(Foxtail::CLDR::Formatter::LocalTimezoneDetector).to receive(:detect)
      .and_return(instance_double(Foxtail::CLDR::Formatter::LocalTimezoneDetector::DetectedTimezone, id: "Asia/Tokyo"))
  end

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
        }.to raise_error(Foxtail::CLDR::Repository::DataNotAvailable)
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
        # UTC 14:30 -> JST 23:30
        expect(result).to eq("11:30 PM")
      end

      it "combines dateStyle and timeStyle" do
        result = formatter.call(test_time, locale: en_locale, dateStyle: "medium", timeStyle: "short")
        # Updated to match current CLDR pattern format (UTC 14:30 -> JST 23:30)
        expect(result).to eq("Jun 15, 2023, 11:30 PM")
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

    context "with custom patterns" do
      let(:en_locale) { locale("en") }
      let(:ja_locale) { locale("ja") }

      it "formats with simple custom pattern" do
        result = formatter.call(test_time, locale: en_locale, pattern: "yyyy-MM-dd")
        expect(result).to eq("2023-06-15")
      end

      it "formats with custom pattern including weekday and month names" do
        result = formatter.call(test_time, locale: en_locale, pattern: "EEEE, MMMM d, yyyy")
        expect(result).to eq("Thursday, June 15, 2023")
      end

      it "formats with abbreviated names in custom pattern" do
        result = formatter.call(test_time, locale: en_locale, pattern: "EEE, MMM d")
        expect(result).to eq("Thu, Jun 15")
      end

      it "formats with time components in custom pattern" do
        result = formatter.call(test_time, locale: en_locale, pattern: "HH:mm:ss")
        # UTC 14:30:45 -> JST 23:30:45
        expect(result).to eq("23:30:45")
      end

      it "formats with 12-hour time in custom pattern" do
        result = formatter.call(test_time, locale: en_locale, pattern: "h:mm a")
        # UTC 14:30 -> JST 23:30 (11:30 PM)
        expect(result).to eq("11:30 PM")
      end

      it "formats with complex custom pattern" do
        result = formatter.call(test_time, locale: en_locale, pattern: "EEEE, d MMMM yyyy 'at' HH:mm")
        # UTC 14:30 -> JST 23:30
        expect(result).to eq("Thursday, 15 June 2023 at 23:30")
      end

      it "uses locale-specific names in custom patterns" do
        result = formatter.call(test_time, locale: ja_locale, pattern: "yyyy年MMMMd日(EEEE)")
        expect(result).to eq("2023年6月15日(木曜日)")
      end

      it "handles literal text in custom patterns" do
        result = formatter.call(test_time, locale: en_locale, pattern: "'Today is' EEEE")
        expect(result).to eq("Today is Thursday")
      end

      it "handles mixed tokens and literals" do
        result = formatter.call(test_time, locale: en_locale, pattern: "'Date:' dd/MM/yyyy 'Time:' HH:mm")
        # UTC 14:30 -> JST 23:30
        expect(result).to eq("Date: 15/06/2023 Time: 23:30")
      end

      it "formats timezone symbols with timeZone option" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")

        # VV: timezone ID
        result = formatter.call(utc_time, locale: en_locale, timeZone: "America/New_York", pattern: "VV")
        expect(result).to eq("America/New_York")

        # VVV: exemplar city
        result = formatter.call(utc_time, locale: en_locale, timeZone: "America/New_York", pattern: "VVV")
        expect(result).to eq("New York") # Extracted from timezone ID

        # ZZZZZ: ISO offset format
        result = formatter.call(utc_time, locale: en_locale, timeZone: "America/New_York", pattern: "ZZZZZ")
        expect(result).to eq("-04:00") # EDT in June

        # Z: basic offset format
        result = formatter.call(utc_time, locale: en_locale, timeZone: "America/New_York", pattern: "Z")
        expect(result).to eq("-0400") # EDT in June
      end

      it "formats complex pattern with timezone symbols" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        result = formatter.call(utc_time, locale: en_locale, timeZone: "Asia/Tokyo", pattern: "yyyy-MM-dd HH:mm VV (ZZZZZ)")
        expect(result).to eq("2023-06-15 23:30 Asia/Tokyo (+09:00)")
      end
    end

    context "with timeZone options" do
      it "formats with UTC timezone" do
        result = formatter.call(test_time, locale: locale("en"), timeZone: "UTC", pattern: "HH:mm")
        # test_time is UTC 14:30, so with UTC timezone option it stays 14:30
        expect(result).to eq("14:30")
      end

      it "formats with offset timezone +09:00" do
        utc_time = Time.new(2023, 6, 15, 5, 30, 45, "+00:00")
        result = formatter.call(utc_time, locale: locale("en"), timeZone: "+09:00", pattern: "HH:mm")
        # 05:30 UTC + 9 hours = 14:30
        expect(result).to eq("14:30")
      end

      it "formats with offset timezone -05:00" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        result = formatter.call(utc_time, locale: locale("en"), timeZone: "-05:00", pattern: "HH:mm")
        # 14:30 UTC - 5 hours = 09:30
        expect(result).to eq("09:30")
      end

      it "preserves original timezone when no timeZone option" do
        result = formatter.call(test_time, locale: locale("en"), pattern: "HH:mm")
        # test_time is UTC 14:30, system timezone is Asia/Tokyo, so 14:30 UTC -> 23:30 JST
        expect(result).to eq("23:30")
      end

      it "formats with IANA timezone America/New_York" do
        # June is during DST, so EDT (UTC-4)
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        result = formatter.call(utc_time, locale: locale("en"), timeZone: "America/New_York", pattern: "HH:mm")
        # 14:30 UTC - 4 hours = 10:30 EDT
        expect(result).to eq("10:30")
      end

      it "formats with IANA timezone Asia/Tokyo" do
        utc_time = Time.new(2023, 6, 15, 5, 30, 45, "+00:00")
        result = formatter.call(utc_time, locale: locale("en"), timeZone: "Asia/Tokyo", pattern: "HH:mm")
        # 05:30 UTC + 9 hours = 14:30 JST
        expect(result).to eq("14:30")
      end

      it "formats with IANA timezone Europe/London" do
        # June is during BST (British Summer Time, UTC+1)
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        result = formatter.call(utc_time, locale: locale("en"), timeZone: "Europe/London", pattern: "HH:mm")
        # 14:30 UTC + 1 hour = 15:30 BST
        expect(result).to eq("15:30")
      end

      it "raises error for invalid timezone" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        expect {
          formatter.call(utc_time, locale: locale("en"), timeZone: "Invalid/Timezone", pattern: "HH:mm")
        }.to raise_error(TZInfo::InvalidTimezoneIdentifier)
      end
    end
  end
end
