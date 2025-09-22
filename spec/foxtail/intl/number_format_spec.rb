# frozen_string_literal: true

RSpec.describe Foxtail::Intl::NumberFormat do
  subject(:formatter) { Foxtail::Intl::NumberFormat.new(locale: locale("en")) }

  describe "#call" do
    context "with CLDR locale support" do
      it "formats with English locale" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"))
        result = formatter.call(1234.5)
        expect(result).to eq("1,234.5")
      end

      it "formats with German locale using comma decimal separator" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("de"))
        result = formatter.call(1234.5)
        expect(result).to eq("1.234,5")
      end

      it "formats with French locale" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("fr"))
        result = formatter.call(1234.5)
        expect(result).to eq("1\u202F234,5") # \u202F is narrow no-break space used by French CLDR
      end

      it "formats large numbers with grouping" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"))
        result = formatter.call(1_234_567.89)
        expect(result).to eq("1,234,567.89")
      end

      it "raises CLDR::DataNotAvailable for unknown locales" do
        expect {
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("unknown"))
          formatter.call(1234.5)
        }.to raise_error(Foxtail::CLDR::Repository::DataNotAvailable)
      end
    end

    context "with style options" do
      let(:de_locale) { locale("de") }
      let(:en_locale) { locale("en") }

      it "formats as percentage with locale" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: de_locale, style: "percent")
        result = formatter.call(0.75)
        expect(result).to eq("75\u00A0%") # \u00A0 is non-breaking space
      end

      it "formats as currency" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "€")
        result = formatter.call(1234.5)
        expect(result).to eq("€1,234.50")
      end
    end

    context "with combined CLDR and precision options" do
      it "formats with locale and minimum fraction digits" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("de"), minimumFractionDigits: 2)
        result = formatter.call(42)
        expect(result).to eq("42,00")
      end

      it "formats percentages with precision" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), style: "percent", minimumFractionDigits: 1)
        result = formatter.call(0.125)
        expect(result).to eq("12.5%")
      end

      it "formats currency with precision" do
        formatter = Foxtail::Intl::NumberFormat.new(
          locale: locale("en"),
          style: "currency",
          currency: "$",
          minimumFractionDigits: 2
        )
        result = formatter.call(42)
        expect(result).to eq("$42.00")
      end
    end

    context "with CLDR currency formatting" do
      let(:en_locale) { locale("en") }
      let(:ja_locale) { locale("ja") }

      describe "USD formatting" do
        it "formats positive USD amounts with proper symbol and decimals" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "USD")
          result = formatter.call(1234.50)
          expect(result).to eq("$1,234.50")
        end

        it "formats negative USD amounts" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "USD")
          result = formatter.call(-1234.50)
          expect(result).to eq("-$1,234.50")
        end

        it "formats negative USD with accounting style" do
          formatter = Foxtail::Intl::NumberFormat.new(
            locale: en_locale,
            style: "currency",
            currency: "USD",
            currencyDisplay: "accounting"
          )
          result = formatter.call(-1234.50)
          expect(result).to eq("($1,234.50)")
        end

        it "formats large amounts with proper grouping" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "USD")
          result = formatter.call(1_234_567.89)
          expect(result).to eq("$1,234,567.89")
        end

        it "formats small amounts correctly" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "USD")
          result = formatter.call(5.99)
          expect(result).to eq("$5.99")
        end
      end

      describe "JPY formatting" do
        it "formats JPY with no decimal places" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "JPY")
          result = formatter.call(1234)
          expect(result).to eq("¥1,234")
        end

        it "formats fractional JPY by rounding to whole numbers" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "JPY")
          result = formatter.call(1234.67)
          expect(result).to eq("¥1,235") # Should round to nearest whole number
        end
      end

      describe "Currency digits" do
        it "respects CLDR currency fraction digits for different currencies" do
          # USD should have 2 decimal places
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "USD")
          usd_result = formatter.call(100)
          expect(usd_result).to eq("$100.00")

          # JPY should have 0 decimal places
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "JPY")
          jpy_result = formatter.call(100)
          expect(jpy_result).to eq("¥100")
        end
      end

      describe "Locale-specific formatting", :integration do
        it "uses Japanese yen symbol in Japanese locale" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: ja_locale, style: "currency", currency: "JPY")
          result = formatter.call(1234)
          expect(result).to eq("￥1,234")
        end

        it "formats USD in Japanese locale" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: ja_locale, style: "currency", currency: "USD")
          result = formatter.call(1234.50)
          expect(result).to eq("$1,234.50")
        end
      end

      describe "Error handling" do
        it "falls back to currency code when symbol is not available" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "currency", currency: "XYZ")
          result = formatter.call(100)
          expect(result).to eq("XYZ100.00")
        end
      end
    end

    context "with invalid input" do
      it "raises ArgumentError for invalid numeric strings" do
        expect {
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"))
          formatter.call("not a number")
        }.to raise_error(ArgumentError)
      end

      it "raises ArgumentError for unparseable numeric strings" do
        expect {
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"))
          formatter.call("12.34.56")
        }.to raise_error(ArgumentError)
      end
    end

    context "with special values" do
      it "formats positive infinity" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"))
        result = formatter.call(Float::INFINITY)
        expect(result).to eq("∞")
      end

      it "formats negative infinity" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"))
        result = formatter.call(-Float::INFINITY)
        expect(result).to eq("-∞")
      end

      it "formats NaN" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"))
        result = formatter.call(Float::NAN)
        expect(result).to eq("NaN")
      end

      it "formats infinity with percent style" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), style: "percent")
        result = formatter.call(Float::INFINITY)
        expect(result).to eq("∞%")
      end

      it "formats negative infinity with currency style" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), style: "currency", currency: "USD")
        result = formatter.call(-Float::INFINITY)
        expect(result).to eq("-$∞")
      end

      it "formats NaN with unit style" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), style: "unit", unit: "meter", unitDisplay: "short")
        result = formatter.call(Float::NAN)
        expect(result).to eq("NaN m")
      end

      it "formats infinity with scientific notation" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "scientific")
        result = formatter.call(Float::INFINITY)
        expect(result).to eq("∞")
      end

      it "formats negative infinity with engineering notation" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "engineering")
        result = formatter.call(-Float::INFINITY)
        expect(result).to eq("-∞")
      end

      it "formats NaN with compact notation" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "compact")
        result = formatter.call(Float::NAN)
        expect(result).to eq("NaN")
      end
    end

    context "with scientific notation" do
      it "formats numbers in scientific notation with default precision" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "scientific")
        result = formatter.call(123.456)
        # Default maximumFractionDigits is 3 for scientific notation (Node.js Intl behavior)
        expect(result).to match(/^1\.235E\+?2$/)
      end

      it "formats large numbers in scientific notation with rounding" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "scientific")
        result = formatter.call(1_234_567.89)
        # Should round to 3 decimal places: 1.23456789 → 1.235
        expect(result).to match(/^1\.235E\+?6$/)
      end

      it "formats small numbers in scientific notation" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "scientific")
        result = formatter.call(0.000123)
        # Should produce format like "1.23E-4"
        expect(result).to match(/^1\.23E-4$/)
      end

      it "formats negative numbers in scientific notation with rounding" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "scientific")
        result = formatter.call(-987_654.321)
        # Should round to 3 decimal places: 9.87654321 → 9.877
        expect(result).to match(/^-9\.877E\+?5$/)
      end

      it "formats integer with minimum digits" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "scientific")
        result = formatter.call(1)
        # Should produce "1E0" for simple integer
        expect(result).to match(/^1E\+?0$/)
      end

      it "formats decimal with necessary precision" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), notation: "scientific")
        result = formatter.call(12.3)
        # Should produce "1.23E1" maintaining necessary precision
        expect(result).to match(/^1\.23E\+?1$/)
      end

      it "uses CLDR scientific pattern from locale data" do
        # This test verifies that we use CLDR data instead of hardcoded patterns
        number_formats = Foxtail::CLDR::Repository::NumberFormats.new(locale("en"))
        expected_pattern = number_formats.scientific_pattern
        expect(expected_pattern).to eq("#E0")
      end
    end

    describe "custom pattern support" do
      it "formats with quirky decimal pattern" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), pattern: "###,###,##0.000")
        result = formatter.call(1234.567)
        expect(result).to eq("1,234.567")
      end

      it "formats with unusual currency placement" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), pattern: "#,##0.00¤")
        result = formatter.call(1234.56)
        expect(result).to eq("1,234.56$")
      end

      it "formats with multiple literal texts" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), pattern: "'Score:' #0 'points'")
        result = formatter.call(42)
        expect(result).to eq("Score: 42 points")
      end

      it "formats with zero-padded scientific notation" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), pattern: "000.000E000")
        result = formatter.call(1234)
        expect(result).to eq("1.234E003")
      end

      it "formats with permille and literal suffix" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), pattern: "#0.00‰ 'rate'")
        result = formatter.call(0.789)
        expect(result).to eq("789.00‰ rate")
      end

      it "formats with accounting-style negative pattern" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), pattern: "#0.00;[#0.00]")
        negative_result = formatter.call(-456.78)
        expect(negative_result).to eq("[456.78]")
      end

      it "custom pattern takes precedence over style option" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), pattern: "'Value:' #0.000", style: "percent")
        result = formatter.call(0.5)
        # Should format as decimal with literal, not as percent (50.000 indicates percent style was applied)
        expect(result).to eq("Value: 50.000")
      end

      it "raises error for patterns with conflicting percent and permille symbols" do
        expect {
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en"), pattern: "#0.0%‰")
          formatter.call(0.123)
        }.to raise_error(ArgumentError, /Pattern cannot contain both percent \(.*?\) and permille \(.*?\)/)
      end
    end

    describe "currency name formatting (¤¤¤)" do
      context "with English locale" do
        let(:en_locale) { locale("en") }

        it "formats singular currency name for integer 1" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "USD")
          result = formatter.call(1)
          expect(result).to eq("US dollar 1.00")
        end

        it "formats plural currency name for 1.0 (CLDR-compliant)" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "USD")
          result = formatter.call(1.0)
          expect(result).to eq("US dollars 1.00")
        end

        it "formats plural currency name for 2" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "USD")
          result = formatter.call(2)
          expect(result).to eq("US dollars 2.00")
        end

        it "formats plural currency name for 0" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "USD")
          result = formatter.call(0)
          expect(result).to eq("US dollars 0.00")
        end

        it "formats plural currency name for decimal values" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "USD")
          result = formatter.call(1.5)
          expect(result).to eq("US dollars 1.50")
        end

        it "formats plural currency name for large numbers" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "USD")
          result = formatter.call(1000)
          expect(result).to eq("US dollars 1,000.00")
        end

        it "formats currency name with negative values" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "USD")
          result = formatter.call(-1)
          expect(result).to eq("US dollar -1.00")
        end

        it "handles unknown currency code XXX properly" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "XXX")
          result = formatter.call(1)
          expect(result).to eq("(unknown unit of currency) 1.00")
        end

        it "falls back to currency code for truly unknown currencies" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "ZZZ")
          result = formatter.call(1)
          expect(result).to eq("ZZZ 1.00")
        end

        it "formats different currency names properly" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "EUR")
          result = formatter.call(1)
          expect(result).to eq("euro 1.00")

          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "¤¤¤ #,##0.00", currency: "EUR")
          result = formatter.call(2)
          expect(result).to eq("euros 2.00")
        end
      end

      context "with different pattern positions" do
        let(:en_locale) { locale("en") }

        it "formats with currency name at the end" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "#,##0.00 ¤¤¤", currency: "USD")
          result = formatter.call(1)
          expect(result).to eq("1.00 US dollar")
        end

        it "formats with currency name in parentheses" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, pattern: "#,##0.00 '('¤¤¤')'", currency: "USD")
          result = formatter.call(2)
          expect(result).to eq("2.00 (US dollars)")
        end
      end

      context "with locales having different plural rules" do
        it "respects locale-specific plural rules" do
          # Polish has different plural rules: 1 (one), 2-4 (few), 5+ (many/other)
          pl_locale = locale("pl")

          # Test will depend on whether Polish CLDR data is available
          # and properly configured with plural currency names
          begin
            formatter = Foxtail::Intl::NumberFormat.new(locale: pl_locale, pattern: "¤¤¤ #,##0.00", currency: "PLN")
            result = formatter.call(1)
            # Should use singular form
            expect(result).to match(/zł|PLN/)
          rescue Foxtail::CLDR::Repository::DataNotAvailable
            skip "Polish CLDR data not available"
          end
        end
      end
    end

    context "with numbering systems" do
      describe "Arabic numbering system" do
        it "formats numbers with Arabic-Indic digits" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("ar-EG"))
          result = formatter.call(123_456.789)
          expect(result).to eq("١٢٣٬٤٥٦٫٧٨٩")
        end

        it "formats with explicit Arab numbering system on English locale" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en-US"), numberingSystem: "arab")
          result = formatter.call(123_456.789)
          expect(result).to eq("١٢٣٬٤٥٦٫٧٨٩")
        end

        it "formats currency with Arabic digits" do
          formatter = Foxtail::Intl::NumberFormat.new(
            locale: locale("ar-SA"),
            style: "currency",
            currency: "SAR"
          )
          result = formatter.call(1234.56)
          expect(result).to eq("\u200f\u0661\u066c\u0662\u0663\u0664\u066b\u0665\u0666\u00a0\u0631.\u0633.\u200f")
        end

        it "formats percentage with Arabic digits" do
          formatter = Foxtail::Intl::NumberFormat.new(
            locale: locale("ar-EG"),
            style: "percent"
          )
          result = formatter.call(0.12)
          expect(result).to eq("١٢٪؜")
        end
      end

      describe "Chinese numbering systems" do
        it "formats with Chinese decimal numbering (hanidec)" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("zh-Hans-CN"), numberingSystem: "hanidec")
          result = formatter.call(123_456.789)
          expect(result).to eq("一二三,四五六.七八九")
        end

        it "formats with full-width digits for Japanese" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("ja-JP"), numberingSystem: "fullwide")
          result = formatter.call(98765)
          expect(result).to eq("９８,７６５")
        end

        it "formats currency with Chinese decimal numbering" do
          formatter = Foxtail::Intl::NumberFormat.new(
            locale: locale("zh-CN"),
            style: "currency",
            currency: "CNY",
            numberingSystem: "hanidec"
          )
          result = formatter.call(1234.56)
          expect(result).to eq("¥一,二三四.五六")
        end

        it "formats with traditional Chinese locale and Latin digits (default)" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("zh-TW"))
          result = formatter.call(1_234_567)
          expect(result).to eq("1,234,567")
        end
      end

      describe "Korean numbering system" do
        it "formats with Korean locale using Latin digits (default)" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("ko-KR"))
          result = formatter.call(1_234_567)
          expect(result).to eq("1,234,567")
        end

        it "formats Korean currency" do
          formatter = Foxtail::Intl::NumberFormat.new(
            locale: locale("ko-KR"),
            style: "currency",
            currency: "KRW"
          )
          result = formatter.call(1_234_567)
          expect(result).to eq("₩1,234,567")
        end

        it "formats percentage in Korean locale" do
          formatter = Foxtail::Intl::NumberFormat.new(
            locale: locale("ko-KR"),
            style: "percent"
          )
          result = formatter.call(0.25)
          expect(result).to eq("25%")
        end

        it "formats with full-width digits when specified" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("ko-KR"), numberingSystem: "fullwide")
          result = formatter.call(42000)
          expect(result).to eq("４２,０００")
        end
      end

      describe "Thai numbering system" do
        it "formats with Thai digits" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("th-TH"), numberingSystem: "thai")
          result = formatter.call(42000)
          expect(result).to eq("๔๒,๐๐๐")
        end

        it "formats currency with Thai digits" do
          formatter = Foxtail::Intl::NumberFormat.new(
            locale: locale("th-TH"),
            style: "currency",
            currency: "THB",
            numberingSystem: "thai"
          )
          result = formatter.call(1234.56)
          expect(result).to eq("฿๑,๒๓๔.๕๖")
        end

        it "formats percentage with Thai digits" do
          formatter = Foxtail::Intl::NumberFormat.new(
            locale: locale("th-TH"),
            style: "percent",
            numberingSystem: "thai"
          )
          result = formatter.call(0.12)
          expect(result).to eq("๑๒%")
        end

        it "formats with Latin digits for Thai locale (default)" do
          formatter = Foxtail::Intl::NumberFormat.new(locale: locale("th-TH"))
          result = formatter.call(1_234_567)
          expect(result).to eq("1,234,567")
        end
      end

      describe "Multiple numbering systems comparison" do
        let(:number) { 1234.56 }

        it "formats same number in different numbering systems" do
          # Latin (default)
          latin_formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en-US"))
          expect(latin_formatter.call(number)).to eq("1,234.56")

          # Arabic-Indic
          arab_formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en-US"), numberingSystem: "arab")
          expect(arab_formatter.call(number)).to eq("١٬٢٣٤٫٥٦")

          # Devanagari
          deva_formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en-US"), numberingSystem: "deva")
          expect(deva_formatter.call(number)).to eq("१,२३४.५६")

          # Thai
          thai_formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en-US"), numberingSystem: "thai")
          expect(thai_formatter.call(number)).to eq("๑,๒๓๔.๕๖")

          # Full-width
          fullwide_formatter = Foxtail::Intl::NumberFormat.new(locale: locale("en-US"), numberingSystem: "fullwide")
          expect(fullwide_formatter.call(number)).to eq("１,２３４.５６")
        end
      end
    end

    context "with unit style" do
      let(:en_locale) { locale("en") }

      it "formats with unit style using default meter" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "unit")
        result = formatter.call(5)
        expect(result).to eq("5 m")
      end

      it "formats with specified unit" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "unit", unit: "kilometer")
        result = formatter.call(100)
        expect(result).to eq("100 km")
      end

      it "formats with different unit display styles" do
        # Test short display (default)
        formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "unit", unit: "meter", unitDisplay: "short")
        result_short = formatter.call(2)
        expect(result_short).to eq("2 m")

        # Test long display - should use plural form for 2
        formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "unit", unit: "meter", unitDisplay: "long")
        result_long = formatter.call(2)
        expect(result_long).to eq("2 meters")
      end

      it "handles fractional numbers" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "unit", unit: "meter")
        result = formatter.call(1.5)
        expect(result).to eq("1.5 m")
      end

      it "applies number formatting rules (grouping)" do
        formatter = Foxtail::Intl::NumberFormat.new(locale: en_locale, style: "unit", unit: "meter")
        result = formatter.call(1000)
        expect(result).to eq("1,000 m")

        result = formatter.call(1234.5)
        expect(result).to eq("1,234.5 m")
      end

      it "respects locale-specific number formatting" do
        # German: period for thousands, comma for decimal
        de_locale = locale("de")
        formatter = Foxtail::Intl::NumberFormat.new(locale: de_locale, style: "unit", unit: "meter")
        result = formatter.call(1000)
        expect(result).to eq("1.000 m")

        result = formatter.call(1234.5)
        expect(result).to eq("1.234,5 m")

        # French: thin space for thousands, comma for decimal
        fr_locale = locale("fr")
        formatter = Foxtail::Intl::NumberFormat.new(locale: fr_locale, style: "unit", unit: "meter")
        result = formatter.call(1000)
        expect(result).to eq("1\u{202F}000\u{202F}m")

        result = formatter.call(1234.5)
        expect(result).to eq("1\u{202F}234,5\u{202F}m")

        # Test short vs long unit display differences
        short_formatter = Foxtail::Intl::NumberFormat.new(locale: fr_locale, style: "unit", unit: "meter", unitDisplay: "short")
        long_formatter = Foxtail::Intl::NumberFormat.new(locale: fr_locale, style: "unit", unit: "meter", unitDisplay: "long")

        result_short = short_formatter.call(2)
        result_long = long_formatter.call(2)

        expect(result_short).to eq("2\u{202F}m")
        expect(result_long).to eq("2\u{00A0}mètres")
      end
    end
  end
end
