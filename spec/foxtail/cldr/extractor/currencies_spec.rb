# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::Currencies do
  let(:fixture_source_dir) { Pathname(Dir.tmpdir) + "test_currencies_source" }
  let(:temp_output_dir) { Pathname(Dir.mktmpdir) }
  let(:extractor) { Foxtail::CLDR::Extractor::Currencies.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  before do
    # Setup fixture source directory
    setup_basic_cldr_fixture(fixture_source_dir)

    # Create parent_locales.yml for Extractor tests
    create_parent_locales_file
  end

  after do
    FileUtils.rm_rf(temp_output_dir)
    FileUtils.rm_rf(fixture_source_dir)
  end

  def create_parent_locales_file
    parent_locales_data = {
      "parent_locales" => {
        "en_AU" => "en_001",
        "en_001" => "en",
        "es_MX" => "es_419"
      }
    }
    (temp_output_dir + "parent_locales.yml").write(parent_locales_data.to_yaml)
  end

  describe "#extract_locale" do
    context "with root locale" do
      it "extracts currency data" do
        extractor.extract_locale("root")

        output_file = temp_output_dir + "root" + "currencies.yml"
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

        output_file = temp_output_dir + "en" + "currencies.yml"
        expect(output_file.exist?).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("en")
        expect(data["currencies"]).to be_a(Hash)
        expect(data["currencies"]).to include("AED", "ADP")
      end
    end
  end

  describe "#extract_all" do
    it "processes all locale files in fixtures" do
      extractor.extract_all

      # Should create files for root, en, ja
      %w[root en ja].each do |locale|
        output_file = temp_output_dir + locale + "currencies.yml"
        expect(output_file.exist?).to be true
      end
    end
  end
end
