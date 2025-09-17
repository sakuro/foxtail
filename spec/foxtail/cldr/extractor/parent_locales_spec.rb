# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::ParentLocales, type: :extractor do
  let(:extractor) { Foxtail::CLDR::Extractor::ParentLocales.new(source_dir:, output_dir:) }

  before do
    # Setup fixture source directory
    setup_extractor_fixture(%w[supplementalData.xml])
  end

  describe "#extract" do
    it "extracts parent locales data to YAML" do
      extractor.extract

      output_file = output_dir + "parent_locales.yml"
      expect(output_file.exist?).to be true

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
      result = extractor.extract

      expect(result).to have_key("parent_locales")
      expect(result["parent_locales"]).to be_a(Hash)
      expect(result["parent_locales"]).to include("en_AU" => "en_001")
    end
  end
end
