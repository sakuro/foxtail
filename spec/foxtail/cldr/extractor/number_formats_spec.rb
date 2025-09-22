# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::NumberFormats, type: :extractor do
  let(:extractor) { Foxtail::CLDR::Extractor::NumberFormats.new(source_dir:, output_dir:) }

  before do
    # Setup fixture source directory
    setup_extractor_fixture(%w[root.xml en.xml ja.xml supplementalData.xml plurals.xml])

    # Setup parent_locales fixture
    setup_parent_locales_fixture
  end

  describe "#extract_locale" do
    context "with root locale" do
      it "extracts number format data" do
        extractor.extract_locale("root")

        output_file = output_dir + "root" + "number_formats.yml"
        expect(output_file.exist?).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("root")
        expect(data["number_formats"]).to be_a(Hash)
        expect(data["number_formats"]["latn"]["symbols"]).to include("decimal", "group")
        expect(data["number_formats"]).not_to have_key("currencies")
      end
    end

    context "with en locale" do
      it "extracts locale-specific data" do
        extractor.extract_locale("en")

        output_file = output_dir + "en" + "number_formats.yml"
        expect(output_file.exist?).to be true

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
  end

  describe "#extract" do
    it "processes all locale files in fixtures" do
      extractor.extract

      # Should create files for root, en, ja
      %w[root en ja].each do |locale|
        output_file = output_dir + locale + "number_formats.yml"
        expect(output_file.exist?).to be true
      end
    end
  end
end
