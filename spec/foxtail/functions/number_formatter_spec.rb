# frozen_string_literal: true

RSpec.describe Foxtail::Functions::NumberFormatter do
  subject(:formatter) { Foxtail::Functions::NumberFormatter.new }

  describe "#call" do
    context "with CLDR locale support" do
      it "formats with English locale" do
        result = formatter.call(1234.5, locale: locale("en"))
        expect(result).to eq("1,234.5")
      end

      it "formats with German locale using comma decimal separator" do
        result = formatter.call(1234.5, locale: locale("de"))
        expect(result).to eq("1.234,5")
      end

      it "formats with French locale" do
        result = formatter.call(1234.5, locale: locale("fr"))
        expect(result).to eq("1\u202F234,5") # \u202F is narrow no-break space used by French CLDR
      end

      it "formats large numbers with grouping" do
        result = formatter.call(1_234_567.89, locale: locale("en"))
        expect(result).to eq("1,234,567.89")
      end

      it "raises CLDR::DataNotAvailable for unknown locales" do
        expect {
          formatter.call(1234.5, locale: locale("unknown"))
        }.to raise_error(Foxtail::CLDR::DataNotAvailable)
      end
    end

    context "with style options" do
      let(:de_locale) { locale("de") }
      let(:en_locale) { locale("en") }

      it "formats as percentage with locale" do
        result = formatter.call(0.75, locale: de_locale, style: "percent")
        expect(result).to eq("75\u00A0%") # \u00A0 is non-breaking space
      end

      it "formats as currency" do
        result = formatter.call(1234.5, locale: en_locale, style: "currency", currency: "€")
        expect(result).to eq("€1,234.50")
      end
    end

    context "with combined CLDR and precision options" do
      it "formats with locale and minimum fraction digits" do
        result = formatter.call(42, locale: locale("de"), minimumFractionDigits: 2)
        expect(result).to eq("42,00")
      end

      it "formats percentages with precision" do
        result = formatter.call(0.125, locale: locale("en"), style: "percent", minimumFractionDigits: 1)
        expect(result).to eq("12.5%")
      end

      it "formats currency with precision" do
        result = formatter.call(
          42,
          locale: locale("en"),
          style: "currency",
          currency: "$",
          minimumFractionDigits: 2
        )
        expect(result).to eq("$42.00")
      end
    end

    context "with CLDR currency formatting" do
      let(:en_locale) { locale("en") }
      let(:ja_locale) { locale("ja") }

      describe "USD formatting" do
        it "formats positive USD amounts with proper symbol and decimals" do
          result = formatter.call(1234.50, locale: en_locale, style: "currency", currency: "USD")
          expect(result).to eq("$1,234.50")
        end

        it "formats negative USD amounts" do
          result = formatter.call(-1234.50, locale: en_locale, style: "currency", currency: "USD")
          expect(result).to eq("$-1,234.50")
        end

        it "formats negative USD with accounting style" do
          result = formatter.call(
            -1234.50,
            locale: en_locale,
            style: "currency",
            currency: "USD",
            currencyDisplay: "accounting"
          )
          expect(result).to eq("($1,234.50)")
        end

        it "formats large amounts with proper grouping" do
          result = formatter.call(1_234_567.89, locale: en_locale, style: "currency", currency: "USD")
          expect(result).to eq("$1,234,567.89")
        end

        it "formats small amounts correctly" do
          result = formatter.call(5.99, locale: en_locale, style: "currency", currency: "USD")
          expect(result).to eq("$5.99")
        end
      end

      describe "JPY formatting" do
        it "formats JPY with no decimal places" do
          result = formatter.call(1234, locale: en_locale, style: "currency", currency: "JPY")
          expect(result).to eq("¥1,234")
        end

        it "formats fractional JPY by rounding to whole numbers" do
          result = formatter.call(1234.67, locale: en_locale, style: "currency", currency: "JPY")
          expect(result).to eq("¥1,235") # Should round to nearest whole number
        end
      end

      describe "Currency digits" do
        it "respects CLDR currency fraction digits for different currencies" do
          # USD should have 2 decimal places
          usd_result = formatter.call(100, locale: en_locale, style: "currency", currency: "USD")
          expect(usd_result).to eq("$100.00")

          # JPY should have 0 decimal places
          jpy_result = formatter.call(100, locale: en_locale, style: "currency", currency: "JPY")
          expect(jpy_result).to eq("¥100")
        end
      end

      describe "Locale-specific formatting", :integration do
        it "uses Japanese yen symbol in Japanese locale" do
          result = formatter.call(1234, locale: ja_locale, style: "currency", currency: "JPY")
          expect(result).to eq("￥1,234")
        end

        it "formats USD in Japanese locale" do
          result = formatter.call(1234.50, locale: ja_locale, style: "currency", currency: "USD")
          expect(result).to eq("$1,234.50")
        end
      end

      describe "Error handling" do
        it "falls back to currency code when symbol is not available" do
          result = formatter.call(100, locale: en_locale, style: "currency", currency: "XYZ")
          expect(result).to eq("XYZ100.00")
        end
      end
    end

    context "with invalid input" do
      it "raises ArgumentError for invalid numeric strings" do
        expect {
          formatter.call("not a number", locale: locale("en"))
        }.to raise_error(ArgumentError)
      end

      it "raises ArgumentError for unparseable numeric strings" do
        expect {
          formatter.call("12.34.56", locale: locale("en"))
        }.to raise_error(ArgumentError)
      end
    end

    context "with scientific notation style" do
      it "formats numbers in scientific notation using CLDR pattern" do
        result = formatter.call(123.456, style: "scientific", locale: locale("en"))
        # CLDR pattern "#E0" produces proper scientific notation with minimum necessary digits
        expect(result).to match(/^1\.23456E\+?2$/)
      end

      it "formats large numbers in scientific notation" do
        result = formatter.call(1_234_567.89, style: "scientific", locale: locale("en"))
        # Should produce format like "1.23456789E6" with necessary significant digits
        expect(result).to match(/^1\.23456789E\+?6$/)
      end

      it "formats small numbers in scientific notation" do
        result = formatter.call(0.000123, style: "scientific", locale: locale("en"))
        # Should produce format like "1.23E-4"
        expect(result).to match(/^1\.23E-4$/)
      end

      it "formats negative numbers in scientific notation" do
        result = formatter.call(-987_654.321, style: "scientific", locale: locale("en"))
        # Should produce format like "-9.87654321E5"
        expect(result).to match(/^-9\.87654321E\+?5$/)
      end

      it "formats integer with minimum digits" do
        result = formatter.call(1, style: "scientific", locale: locale("en"))
        # Should produce "1E0" for simple integer
        expect(result).to match(/^1E\+?0$/)
      end

      it "formats decimal with necessary precision" do
        result = formatter.call(12.3, style: "scientific", locale: locale("en"))
        # Should produce "1.23E1" maintaining necessary precision
        expect(result).to match(/^1\.23E\+?1$/)
      end

      it "uses CLDR scientific pattern from locale data" do
        # This test verifies that we use CLDR data instead of hardcoded patterns
        number_formats = Foxtail::CLDR::NumberFormats.new(locale("en"))
        expected_pattern = number_formats.scientific_pattern
        expect(expected_pattern).to eq("#E0")
      end
    end

    describe "custom pattern support" do
      it "formats with quirky decimal pattern" do
        result = formatter.call(1234.567, pattern: "###,###,##0.000", locale: locale("en"))
        expect(result).to eq("1,234.567")
      end

      it "formats with unusual currency placement" do
        result = formatter.call(1234.56, pattern: "#,##0.00¤", locale: locale("en"))
        expect(result).to eq("1,234.56$")
      end

      it "formats with multiple literal texts" do
        result = formatter.call(42, pattern: "'Score:' #0 'points'", locale: locale("en"))
        expect(result).to eq("Score: 42 points")
      end

      it "formats with zero-padded scientific notation" do
        result = formatter.call(1234, pattern: "000.0E000", locale: locale("en"))
        expect(result).to eq("1.234E003")
      end

      it "formats with permille and literal suffix" do
        result = formatter.call(0.789, pattern: "#0.00‰ 'rate'", locale: locale("en"))
        expect(result).to eq("789.00‰ rate")
      end

      it "formats with accounting-style negative pattern" do
        negative_result = formatter.call(-456.78, pattern: "#0.00;[#0.00]", locale: locale("en"))
        expect(negative_result).to eq("[456.78]")
      end

      it "custom pattern takes precedence over style option" do
        result = formatter.call(0.5, pattern: "'Value:' #0.000", style: "percent", locale: locale("en"))
        # Should format as decimal with literal, not as percent (50.000 indicates percent style was applied)
        expect(result).to eq("Value: 50.000")
      end

      it "raises error for patterns with conflicting percent and permille symbols" do
        expect {
          formatter.call(0.123, pattern: "#0.0%‰", locale: locale("en"))
        }.to raise_error(ArgumentError, /Pattern cannot contain both percent \(.*?\) and permille \(.*?\)/)
      end
    end
  end
end
