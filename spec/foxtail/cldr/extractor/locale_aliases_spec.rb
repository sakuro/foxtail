# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::LocaleAliases do
  let(:fixture_source_dir) { File.join(__dir__, "..", "..", "..", "fixtures", "cldr") }
  let(:temp_output_dir) { Dir.mktmpdir }
  let(:extractor) { Foxtail::CLDR::Extractor::LocaleAliases.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  after do
    FileUtils.rm_rf(temp_output_dir)
  end

  describe "#extract_all" do
    it "extracts locale aliases from fixture files" do
      extractor.extract_all

      output_file = File.join(temp_output_dir, "locale_aliases.yml")
      expect(File.exist?(output_file)).to be true

      data = YAML.load_file(output_file)
      expect(data["locale_aliases"]).to be_a(Hash)
      expect(data["locale_aliases"]).not_to be_empty
    end

    it "includes zh_TW -> zh_Hant_TW mapping" do
      extractor.extract_all

      output_file = File.join(temp_output_dir, "locale_aliases.yml")
      data = YAML.load_file(output_file)

      expect(data["locale_aliases"]).to include("zh_TW" => "zh_Hant_TW")
    end
  end

  describe "private methods" do
    describe "#load_traditional_aliases" do
      it "loads from supplementalMetadata.xml" do
        aliases = extractor.__send__(:load_traditional_aliases)

        expect(aliases).to be_a(Hash)
        expect(aliases).not_to be_empty
      end
    end

    describe "#load_likely_subtag_aliases" do
      it "loads from likelySubtags.xml" do
        aliases = extractor.__send__(:load_likely_subtag_aliases)

        expect(aliases).to be_a(Hash)
        expect(aliases).to include("zh_TW" => "zh_Hant_TW")
      end
    end
  end
end
