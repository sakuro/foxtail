# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::Units, type: :extractor do
  let(:extractor) { Foxtail::CLDR::Extractor::Units.new(source_dir:, output_dir:) }

  before do
    # Setup fixture source directory
    setup_extractor_fixture(%w[root.xml en.xml ja.xml supplementalData.xml plurals.xml])

    # Setup parent_locales fixture
    setup_parent_locales_fixture
  end

  describe "#extract_locale" do
    it "extracts units data for a locale" do
      extractor.extract_locale("en")

      units_file = output_dir + "en" + "units.yml"
      expect(units_file.exist?).to be(true)

      data = YAML.load_file(units_file)
      expect(data).to have_key("units")
      expect(data["units"]).to be_a(Hash)
    end
  end

  describe "#data?" do
    it "returns true for valid units data" do
      valid_data = {
        "units" => {
          "meter" => {
            "long" => {"display_name" => "meters"},
            "category" => "length"
          }
        }
      }
      expect(extractor.__send__(:data?, valid_data)).to be(true)
    end

    it "returns false for empty units data" do
      empty_data = {"units" => {}}
      expect(extractor.__send__(:data?, empty_data)).to be(false)
    end

    it "returns false for invalid data structure" do
      invalid_data = {"units" => "not a hash"}
      expect(extractor.__send__(:data?, invalid_data)).to be(false)
    end
  end
end
