# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::Currencies, type: :extractor do
  let(:extractor) { Foxtail::CLDR::Extractor::Currencies.new(source_dir:, output_dir:) }

  before do
    # Setup fixture source directory
    setup_extractor_fixture(%w[root.xml en.xml ja.xml supplementalData.xml plurals.xml])

    # Setup parent_locales fixture
    setup_parent_locales_fixture
  end

  describe "#extract_locale" do
    context "with root locale" do
      it "extracts currency data" do
        extractor.extract_locale("root")

        output_file = output_dir + "root" + "currencies.yml"
        expect(output_file.exist?).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("root")
        expect(data["cldr_version"]).to be_a(String)
        expect(data["generated_at"]).to be_a(String)
        expect(data["currencies"]).to be_a(Hash)
        expect(data["currencies"]).to include("USD", "AUD")
      end
    end

    context "with en locale" do
      it "extracts locale-specific currency data" do
        extractor.extract_locale("en")

        output_file = output_dir + "en" + "currencies.yml"
        expect(output_file.exist?).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("en")
        expect(data["currencies"]).to be_a(Hash)
        expect(data["currencies"]).to include("AED", "ADP")
      end
    end
  end

  describe "#extract" do
    it "processes all locale files in fixtures" do
      extractor.extract

      # Should create files for root, en, ja
      %w[root en ja].each do |locale|
        output_file = output_dir + locale + "currencies.yml"
        expect(output_file.exist?).to be true
      end
    end
  end
end
