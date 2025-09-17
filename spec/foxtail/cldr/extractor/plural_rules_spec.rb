# frozen_string_literal: true

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

      # Should create plural rules for locales with distinct rules (not ja which falls back to root)
      %w[en ru].each do |locale|
        output_file = output_dir + locale + "plural_rules.yml"

        expect(output_file.exist?).to be(true), "Expected #{output_file} to be created for locale #{locale}"

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq(locale)
        expect(data["plural_rules"]).to be_a(Hash)
      end

      # ja should not have its own file as it falls back to root
      ja_file = output_dir + "ja" + "plural_rules.yml"
      expect(ja_file.exist?).to be(false), "ja locale should fall back to root, not create its own file"
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
