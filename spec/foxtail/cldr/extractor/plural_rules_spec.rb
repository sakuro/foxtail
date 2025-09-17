# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::PluralRules, type: :extractor do
  let(:extractor) { Foxtail::CLDR::Extractor::PluralRules.new(source_dir:, output_dir:) }

  before do
    # Setup fixture source directory
    setup_extractor_fixture(%w[plurals.xml])
    # Setup parent locales fixture for inheritance processing
    setup_parent_locales_fixture
  end

  describe "#extract" do
    it "extracts plural rules from fixture supplemental data" do
      extractor.extract

      # Should create plural rules for various locales
      %w[en ja ru].each do |locale|
        output_file = output_dir + locale + "plural_rules.yml"

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

      output_file = output_dir + "en" + "plural_rules.yml"
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
        doc = REXML::Document.new((source_dir + "common" + "supplemental" + "plurals.xml").read)
        locale_rules = extractor.__send__(:extract_all_locales_from_supplemental, doc)

        expect(locale_rules).to be_a(Hash)
        expect(locale_rules).to include("en")
        expect(locale_rules["en"]).to be_a(Hash)
      end
    end
  end
end
