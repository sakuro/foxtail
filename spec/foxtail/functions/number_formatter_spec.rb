# frozen_string_literal: true

require "locale"

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
        expect(result).to eq("€1,234.5")
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
  end
end
