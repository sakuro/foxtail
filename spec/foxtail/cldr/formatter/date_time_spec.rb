# frozen_string_literal: true

require "time"

RSpec.describe Foxtail::CLDR::Formatter::DateTime do
  subject(:formatter) { Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en")) }

  let(:test_time) { Time.utc(2023, 6, 15, 14, 30, 45) }

  # Stub timezone detection to return JST for consistent test results
  before do
    allow(Foxtail::CLDR::Formatter::LocalTimezoneDetector).to receive(:detect)
      .and_return(instance_double(Foxtail::CLDR::Formatter::LocalTimezoneDetector::DetectedTimezone, id: "Asia/Tokyo"))
  end

  describe "#call" do
    context "with locale options" do
      it "formats with English locale" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "full")
        result = formatter.call(test_time)
        expect(result).to eq("Thursday, June 15, 2023")
      end

      it "formats with Japanese locale" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("ja"), dateStyle: "full")
        result = formatter.call(test_time)
        expect(result).to eq("2023年6月15日木曜日")
      end

      it "formats month names in Japanese" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("ja"), month: "long")
        result = formatter.call(test_time)
        expect(result).to eq("6月")
      end

      it "formats weekday names in Japanese" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("ja"), weekday: "long")
        result = formatter.call(test_time)
        expect(result).to eq("木曜日")
      end

      it "raises CLDR::DataNotAvailable for unknown locales" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("unknown"), month: "long")
          formatter.call(test_time)
        }.to raise_error(Foxtail::CLDR::Repository::DataNotAvailable)
      end
    end

    context "with different date/time styles" do
      let(:en_locale) { locale("en") }

      it "formats with dateStyle medium" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, dateStyle: "medium")
        result = formatter.call(test_time)
        expect(result).to eq("Jun 15, 2023")
      end

      it "formats with dateStyle full" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, dateStyle: "full")
        result = formatter.call(test_time)
        expect(result).to eq("Thursday, June 15, 2023")
      end

      it "formats with timeStyle short" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, timeStyle: "short")
        result = formatter.call(test_time)
        # UTC 14:30 -> JST 23:30
        expect(result).to eq("11:30 PM")
      end

      it "combines dateStyle and timeStyle" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, dateStyle: "medium", timeStyle: "short")
        result = formatter.call(test_time)
        # Updated to match current CLDR pattern format (UTC 14:30 -> JST 23:30)
        expect(result).to eq("Jun 15, 2023, 11:30 PM")
      end
    end

    context "with invalid input" do
      it "raises ArgumentError for invalid date strings" do
        expect {
          formatter.call("not a date")
        }.to raise_error(ArgumentError)
      end

      it "raises ArgumentError for unparseable date strings" do
        expect {
          formatter.call("2023-13-99")
        }.to raise_error(ArgumentError)
      end
    end

    context "with custom patterns" do
      let(:en_locale) { locale("en") }
      let(:ja_locale) { locale("ja") }

      it "formats with simple custom pattern" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, pattern: "yyyy-MM-dd")
        result = formatter.call(test_time)
        expect(result).to eq("2023-06-15")
      end

      it "formats with custom pattern including weekday and month names" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, pattern: "EEEE, MMMM d, yyyy")
        result = formatter.call(test_time)
        expect(result).to eq("Thursday, June 15, 2023")
      end

      it "formats with abbreviated names in custom pattern" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, pattern: "EEE, MMM d")
        result = formatter.call(test_time)
        expect(result).to eq("Thu, Jun 15")
      end

      it "formats with time components in custom pattern" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, pattern: "HH:mm:ss")
        result = formatter.call(test_time)
        # UTC 14:30:45 -> JST 23:30:45
        expect(result).to eq("23:30:45")
      end

      it "formats with 12-hour time in custom pattern" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, pattern: "h:mm a")
        result = formatter.call(test_time)
        # UTC 14:30 -> JST 23:30 (11:30 PM)
        expect(result).to eq("11:30 PM")
      end

      it "formats with complex custom pattern" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, pattern: "EEEE, d MMMM yyyy 'at' HH:mm")
        result = formatter.call(test_time)
        # UTC 14:30 -> JST 23:30
        expect(result).to eq("Thursday, 15 June 2023 at 23:30")
      end

      it "uses locale-specific names in custom patterns" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: ja_locale, pattern: "yyyy年MMMMd日(EEEE)")
        result = formatter.call(test_time)
        expect(result).to eq("2023年6月15日(木曜日)")
      end

      it "handles literal text in custom patterns" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, pattern: "'Today is' EEEE")
        result = formatter.call(test_time)
        expect(result).to eq("Today is Thursday")
      end

      it "handles mixed tokens and literals" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, pattern: "'Date:' dd/MM/yyyy 'Time:' HH:mm")
        result = formatter.call(test_time)
        # UTC 14:30 -> JST 23:30
        expect(result).to eq("Date: 15/06/2023 Time: 23:30")
      end

      it "formats timezone symbols with timeZone option" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")

        # VV: timezone ID
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, timeZone: "America/New_York", pattern: "VV")
        result = formatter.call(utc_time)
        expect(result).to eq("America/New_York")

        # VVV: exemplar city
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, timeZone: "America/New_York", pattern: "VVV")
        result = formatter.call(utc_time)
        expect(result).to eq("New York") # Extracted from timezone ID

        # ZZZZZ: ISO offset format
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, timeZone: "America/New_York", pattern: "ZZZZZ")
        result = formatter.call(utc_time)
        expect(result).to eq("-04:00") # EDT in June

        # Z: basic offset format
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, timeZone: "America/New_York", pattern: "Z")
        result = formatter.call(utc_time)
        expect(result).to eq("-0400") # EDT in June
      end

      it "formats complex pattern with timezone symbols" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, timeZone: "Asia/Tokyo", pattern: "yyyy-MM-dd HH:mm VV (ZZZZZ)")
        result = formatter.call(utc_time)
        expect(result).to eq("2023-06-15 23:30 Asia/Tokyo (+09:00)")
      end
    end

    context "with timeZone options" do
      it "formats with UTC timezone" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "UTC", pattern: "HH:mm")
        result = formatter.call(test_time)
        # test_time is UTC 14:30, so with UTC timezone option it stays 14:30
        expect(result).to eq("14:30")
      end

      it "formats with offset timezone +09:00" do
        utc_time = Time.new(2023, 6, 15, 5, 30, 45, "+00:00")
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "+09:00", pattern: "HH:mm")
        result = formatter.call(utc_time)
        # 05:30 UTC + 9 hours = 14:30
        expect(result).to eq("14:30")
      end

      it "formats with offset timezone -05:00" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "-05:00", pattern: "HH:mm")
        result = formatter.call(utc_time)
        # 14:30 UTC - 5 hours = 09:30
        expect(result).to eq("09:30")
      end

      it "preserves original timezone when no timeZone option" do
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), pattern: "HH:mm")
        result = formatter.call(test_time)
        # test_time is UTC 14:30, system timezone is Asia/Tokyo, so 14:30 UTC -> 23:30 JST
        expect(result).to eq("23:30")
      end

      it "formats with IANA timezone America/New_York" do
        # June is during DST, so EDT (UTC-4)
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "America/New_York", pattern: "HH:mm")
        result = formatter.call(utc_time)
        # 14:30 UTC - 4 hours = 10:30 EDT
        expect(result).to eq("10:30")
      end

      it "formats with IANA timezone Asia/Tokyo" do
        utc_time = Time.new(2023, 6, 15, 5, 30, 45, "+00:00")
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "Asia/Tokyo", pattern: "HH:mm")
        result = formatter.call(utc_time)
        # 05:30 UTC + 9 hours = 14:30 JST
        expect(result).to eq("14:30")
      end

      it "formats with IANA timezone Europe/London" do
        # June is during BST (British Summer Time, UTC+1)
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "Europe/London", pattern: "HH:mm")
        result = formatter.call(utc_time)
        # 14:30 UTC + 1 hour = 15:30 BST
        expect(result).to eq("15:30")
      end

      it "raises error for invalid timezone" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "Invalid/Timezone", pattern: "HH:mm")
          formatter.call(utc_time)
        }.to raise_error(TZInfo::InvalidTimezoneIdentifier)
      end

      it "formats timezone names with different patterns" do
        utc_time = Time.new(2023, 6, 15, 14, 30, 45, "+00:00")

        # Test Etc/UTC timezone handling
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "Etc/UTC", pattern: "z")
        result = formatter.call(utc_time)
        expect(result).to be_a(String)
        expect(result).not_to be_empty

        # Test offset format timezone
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), timeZone: "+09:00", pattern: "z")
        result = formatter.call(utc_time)
        expect(result).to be_a(String)
        expect(result).not_to be_empty

        # Test GMT metazone with different locales
        formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("fr"), timeZone: "UTC", pattern: "z")
        result = formatter.call(utc_time)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end

    context "with individual field options" do
      let(:midnight_utc) { Time.new(2023, 12, 25, 0, 0, 0, "+00:00") }
      let(:en_locale) { locale("en") }
      let(:de_locale) { locale("de") }
      let(:fr_locale) { locale("fr") }
      let(:ja_locale) { locale("ja") }

      # Test hour field adaptation with different options
      describe "hour field formatting" do
        it "formats hour as numeric (1-digit for non-zero)" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, hour: "numeric", minute: "2-digit", second: "2-digit", hour12: false, timeZone: "UTC")
          result = formatter.call(midnight_utc)
          # Should follow CLDR pattern for English (HH -> keep as 2-digit for en-US)
          expect(result).to match(/\d{1,2}:00:00/)
        end

        it "formats hour as 2-digit (always padded)" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false, timeZone: "UTC")
          result = formatter.call(midnight_utc)
          expect(result).to eq("00:00:00")
        end

        it "handles different locales with hour numeric" do
          # Test multiple locales to ensure pattern adaptation works
          [en_locale, de_locale, fr_locale, ja_locale].each do |test_locale|
            formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: test_locale, hour: "numeric", minute: "2-digit", hour12: false, timeZone: "UTC")
            result = formatter.call(midnight_utc)
            expect(result).to match(/\d{1,2}:00/) # Should have proper hour formatting
          end
        end

        it "handles 12-hour format with hour options" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, hour: "numeric", minute: "2-digit", hour12: true, timeZone: "UTC")
          result = formatter.call(midnight_utc)
          expect(result).to match(/\d{1,2}:00 (AM|PM)/)
        end

        it "handles non-zero hours with numeric formatting" do
          one_pm_utc = Time.new(2023, 12, 25, 13, 0, 0, "+00:00")
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, hour: "numeric", minute: "2-digit", hour12: false, timeZone: "UTC")
          result = formatter.call(one_pm_utc)
          expect(result).to match(/1?3:00/)
        end
      end

      # Test minute and second field formatting
      describe "minute and second field formatting" do
        it "formats minute as 2-digit" do
          five_minutes_utc = Time.new(2023, 12, 25, 0, 5, 0, "+00:00")
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, hour: "numeric", minute: "2-digit", hour12: false, timeZone: "UTC")
          result = formatter.call(five_minutes_utc)
          expect(result).to match(/\d{1,2}:05/)
        end

        it "formats second as 2-digit" do
          five_seconds_utc = Time.new(2023, 12, 25, 0, 0, 5, "+00:00")
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, hour: "numeric", minute: "2-digit", second: "2-digit", hour12: false, timeZone: "UTC")
          result = formatter.call(five_seconds_utc)
          expect(result).to match(/\d{1,2}:00:05/)
        end
      end

      # Test single field formatting (triggers format_fields_individually)
      describe "single field formatting" do
        it "formats only weekday" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, weekday: "long")
          result = formatter.call(test_time)
          expect(result).to eq("Thursday")
        end

        it "formats only month" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, month: "long")
          result = formatter.call(test_time)
          expect(result).to eq("June")
        end

        it "formats only year" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, year: "numeric")
          result = formatter.call(test_time)
          expect(result).to eq("2023")
        end

        it "formats only day" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, day: "numeric")
          result = formatter.call(test_time)
          expect(result).to eq("15")
        end

        it "formats only hour" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, hour: "numeric", hour12: false, timeZone: "UTC")
          result = formatter.call(test_time)
          expect(result).to eq("14")
        end
      end

      # Test complex field combinations that might trigger fallback patterns
      describe "complex field combinations" do
        it "handles hour, minute, second combination" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false, timeZone: "UTC")
          result = formatter.call(test_time)
          expect(result).to eq("14:30:45")
        end

        it "handles year, month, day combination" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, year: "numeric", month: "long", day: "numeric")
          result = formatter.call(test_time)
          expect(result).to eq("June 15, 2023")
        end

        it "handles weekday, year, month, day combination" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, weekday: "long", year: "numeric", month: "short", day: "numeric")
          result = formatter.call(test_time)
          expect(result).to eq("Thursday, Jun 15, 2023")
        end

        it "handles mixed date and time fields" do
          formatter = Foxtail::CLDR::Formatter::DateTime.new(
            locale: en_locale,
            year: "numeric",
            month: "short",
            day: "numeric",
            hour: "numeric",
            minute: "2-digit",
            hour12: true,
            timeZone: "UTC"
          )
          result = formatter.call(test_time)
          # Mixed date and time fields should produce both date and time
          # timeZone: "UTC" keeps the time at 14:30 UTC = 2:30 PM in 12-hour format
          expect(result).to eq("Jun 15, 2023, 2:30 PM")
        end
      end

      # Test different width options for the same field
      describe "field width variations" do
        it "handles different month widths" do
          test_cases = [
            {width: "numeric", expected: "6"},
            {width: "2-digit", expected: "06"},
            {width: "short", expected: "Jun"},
            {width: "long", expected: "June"}
          ]

          test_cases.each do |test_case|
            formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, month: test_case[:width])
            result = formatter.call(test_time)
            expect(result).to eq(test_case[:expected])
          end
        end

        it "handles different weekday widths" do
          test_cases = [
            {width: "short", expected: "Thu"},
            {width: "long", expected: "Thursday"}
          ]

          test_cases.each do |test_case|
            formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: en_locale, weekday: test_case[:width])
            result = formatter.call(test_time)
            expect(result).to eq(test_case[:expected])
          end
        end
      end
    end

    context "with special values (Infinity, NaN)" do
      it "raises an error for positive infinity" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call(Float::INFINITY)
        }.to raise_error(ArgumentError, /special value|invalid.*time/i)
      end

      it "raises an error for negative infinity" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call(-Float::INFINITY)
        }.to raise_error(ArgumentError, /special value|invalid.*time/i)
      end

      it "raises an error for NaN" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call(Float::NAN)
        }.to raise_error(ArgumentError, /special value|invalid.*time/i)
      end

      it "raises an error for string representations of infinity" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call("Infinity")
        }.to raise_error(ArgumentError, /special value|invalid.*time/i)
      end

      it "raises an error for string representations of negative infinity" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call("-Infinity")
        }.to raise_error(ArgumentError, /special value|invalid.*time/i)
      end

      it "raises an error for string representations of NaN" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call("NaN")
        }.to raise_error(ArgumentError, /special value|invalid.*time/i)
      end

      it "raises an error for extremely large numeric strings that overflow to infinity" do
        # String with 400 digits that will overflow to Infinity when converted to Float
        huge_number_string = "1#{"0" * 400}"
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call(huge_number_string)
        }.to raise_error(ArgumentError, /special value|overflow|invalid.*time/i)
      end

      it "raises an error for numeric strings with extremely large exponents" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call("1.0e309")
        }.to raise_error(ArgumentError, /special value|overflow|invalid.*time/i)
      end

      it "raises an error for numeric strings exceeding Float::MAX" do
        expect {
          formatter = Foxtail::CLDR::Formatter::DateTime.new(locale: locale("en"), dateStyle: "medium")
          formatter.call("1.8e308")
        }.to raise_error(ArgumentError, /special value|overflow|invalid.*time/i)
      end
    end
  end
end
