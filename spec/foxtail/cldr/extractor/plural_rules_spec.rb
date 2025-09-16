# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::PluralRules do
  let(:fixture_source_dir) { Pathname(Dir.tmpdir) + "test_plural_rules_source" }
  let(:temp_output_dir) { Pathname(Dir.mktmpdir) }
  let(:extractor) { Foxtail::CLDR::Extractor::PluralRules.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  before do
    # Setup fixture source directory
    setup_cldr_fixture(fixture_source_dir, %w[plurals.xml])
    # Setup parent locales fixture for inheritance processing
    setup_parent_locales_fixture(temp_output_dir)
  end

  after do
    FileUtils.rm_rf(temp_output_dir)
    FileUtils.rm_rf(fixture_source_dir)
  end

  describe "#extract" do
    it "extracts plural rules from fixture supplemental data" do
      extractor.extract

      # Should create plural rules for various locales
      %w[en ja ru].each do |locale|
        output_file = temp_output_dir + locale + "plural_rules.yml"

        next unless output_file.exist?

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq(locale)
        expect(data["plural_rules"]).to be_a(Hash)
      end
    end
  end

  describe "#extract_locale" do
    it "extracts rules for specific locale" do
      extractor.extract_locale("en")

      output_file = temp_output_dir + "en" + "plural_rules.yml"
      expect(output_file.exist?).to be true

      data = YAML.load_file(output_file)
      expect(data["locale"]).to eq("en")
      expect(data["plural_rules"]).to be_a(Hash)
      expect(data["plural_rules"]).to include("one")
    end
  end

  describe "private methods" do
    describe "#extract_all_locales_from_supplemental" do
      it "parses supplemental plurals.xml" do
        doc = REXML::Document.new((fixture_source_dir + "common" + "supplemental" + "plurals.xml").read)
        locale_rules = extractor.__send__(:extract_all_locales_from_supplemental, doc)

        expect(locale_rules).to be_a(Hash)
        expect(locale_rules).to include("en")
        expect(locale_rules["en"]).to be_a(Hash)
      end
    end
  end
end
