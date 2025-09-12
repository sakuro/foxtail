# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractors::NumberFormatsExtractor do
  let(:fixture_source_dir) { File.join(__dir__, "..", "..", "..", "fixtures", "cldr") }
  let(:temp_output_dir) { Dir.mktmpdir }
  let(:extractor) { Foxtail::CLDR::Extractors::NumberFormatsExtractor.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  before do
    # Stub log method to prevent output during tests
    allow(extractor).to receive(:log)
  end

  after do
    FileUtils.rm_rf(temp_output_dir)
  end

  describe "#extract_locale" do
    context "with root locale" do
      it "extracts number format data" do
        extractor.extract_locale("root")

        output_file = File.join(temp_output_dir, "root", "number_formats.yml")
        expect(File.exist?(output_file)).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("root")
        expect(data["number_formats"]).to be_a(Hash)
        expect(data["number_formats"]["symbols"]).to include("decimal", "group")
        expect(data["number_formats"]["currencies"]).to include("USD", "EUR")
      end
    end

    context "with en locale" do
      it "extracts locale-specific data" do
        extractor.extract_locale("en")

        output_file = File.join(temp_output_dir, "en", "number_formats.yml")
        expect(File.exist?(output_file)).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("en")
        expect(data["number_formats"]).to be_a(Hash)
      end
    end
  end

  describe "private methods using source_dir" do
    describe "#extract_currency_fractions" do
      it "reads from fixture supplemental data" do
        fractions = extractor.__send__(:extract_currency_fractions)

        expect(fractions).to be_a(Hash)
        expect(fractions).not_to be_empty
        # Check some known currencies with special fraction rules
        expect(fractions).to include("JPY") # 0 digits
        expect(fractions["JPY"]).to include("digits" => 0)
      end
    end

    describe "#load_root_currencies" do
      it "reads from fixture root.xml" do
        currencies = extractor.__send__(:load_root_currencies)

        expect(currencies).to be_a(Hash)
        expect(currencies).to include("USD")
        expect(currencies["USD"]).to include("symbol")
        # The actual symbol from CLDR root is "US$"
        expect(currencies["USD"]["symbol"]).to eq("US$")
      end
    end
  end

  describe "#extract_all" do
    it "processes all locale files in fixtures" do
      extractor.extract_all

      # Should create files for root, en, ja
      %w[root en ja].each do |locale|
        output_file = File.join(temp_output_dir, locale, "number_formats.yml")
        expect(File.exist?(output_file)).to be true
      end
    end
  end
end
