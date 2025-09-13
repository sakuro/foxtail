# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::ParentLocales do
  let(:fixture_source_dir) { File.join(Dir.tmpdir, "test_parent_locales_source") }
  let(:temp_output_dir) { Dir.mktmpdir }
  let(:extractor) { Foxtail::CLDR::Extractor::ParentLocales.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  before do
    # Setup fixture source directory
    setup_cldr_fixture(fixture_source_dir, %w[supplementalData.xml])
  end

  after do
    FileUtils.rm_rf(temp_output_dir)
    FileUtils.rm_rf(fixture_source_dir)
  end

  describe "#extract_all" do
    it "extracts parent locales data to YAML" do
      extractor.extract_all

      output_file = File.join(temp_output_dir, "parent_locales.yml")
      expect(File.exist?(output_file)).to be true

      data = YAML.load_file(output_file)
      expect(data).to have_key("parent_locales")
      expect(data["parent_locales"]).to be_a(Hash)

      # Check for some known parent locale mappings from fixtures
      parent_locales = data["parent_locales"]
      expect(parent_locales).to include("en_AU" => "en_001")
      expect(parent_locales).to include("en_150" => "en_001")
      expect(parent_locales).to include("es_MX" => "es_419")

      # NOTE: en_001 -> en is not explicitly defined in CLDR,
      # it's resolved algorithmically
    end

    it "returns parent locales data" do
      result = extractor.extract_all

      expect(result).to have_key("parent_locales")
      expect(result["parent_locales"]).to be_a(Hash)
      expect(result["parent_locales"]).to include("en_AU" => "en_001")
    end
  end
end
