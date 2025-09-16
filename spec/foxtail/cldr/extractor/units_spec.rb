# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::Units do
  let(:fixture_source_dir) { Pathname(Dir.tmpdir) + "test_units_source" }
  let(:temp_output_dir) { Pathname(Dir.mktmpdir) }
  let(:extractor) { Foxtail::CLDR::Extractor::Units.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

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
        "ja_JP" => "ja"
      }
    }

    parent_locales_file = temp_output_dir + "parent_locales.yml"
    parent_locales_file.dirname.mkpath
    parent_locales_file.write(YAML.dump(parent_locales_data))
  end

  describe "#extract_locale" do
    it "extracts units data for a locale" do
      extractor.extract_locale("en")

      units_file = temp_output_dir + "en" + "units.yml"
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
