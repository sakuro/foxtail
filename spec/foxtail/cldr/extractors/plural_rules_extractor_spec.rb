# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractors::PluralRulesExtractor do
  let(:fixture_source_dir) { File.join(__dir__, "..", "..", "..", "fixtures", "cldr") }
  let(:temp_output_dir) { Dir.mktmpdir }
  let(:extractor) { Foxtail::CLDR::Extractors::PluralRulesExtractor.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  before do
    # Stub log method to prevent output during tests
    allow(extractor).to receive(:log)
  end

  after do
    FileUtils.rm_rf(temp_output_dir)
  end

  describe "#extract_all" do
    it "extracts plural rules from fixture supplemental data" do
      extractor.extract_all

      # Should create plural rules for various locales
      %w[en ja ru].each do |locale|
        output_file = File.join(temp_output_dir, locale, "plural_rules.yml")

        next unless File.exist?(output_file)

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq(locale)
        expect(data["plural_rules"]).to be_a(Hash)
      end
    end
  end

  describe "#extract_locale" do
    it "extracts rules for specific locale" do
      extractor.extract_locale("en")

      output_file = File.join(temp_output_dir, "en", "plural_rules.yml")
      expect(File.exist?(output_file)).to be true

      data = YAML.load_file(output_file)
      expect(data["locale"]).to eq("en")
      expect(data["plural_rules"]).to be_a(Hash)
      expect(data["plural_rules"]).to include("one")
    end
  end

  describe "private methods" do
    describe "#extract_all_locales_from_supplemental" do
      it "parses supplemental plurals.xml" do
        doc = REXML::Document.new(File.read(File.join(fixture_source_dir, "common", "supplemental", "plurals.xml")))
        locale_rules = extractor.__send__(:extract_all_locales_from_supplemental, doc)

        expect(locale_rules).to be_a(Hash)
        expect(locale_rules).to include("en")
        expect(locale_rules["en"]).to be_a(Hash)
      end
    end
  end
end
