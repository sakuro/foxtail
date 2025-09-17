# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::MetazoneMapping, type: :extractor do
  let(:extractor) { Foxtail::CLDR::Extractor::MetazoneMapping.new(source_dir:, output_dir:) }

  before do
    # Setup fixture source directory with metaZones.xml
    setup_extractor_fixture(%w[metaZones.xml])
  end

  describe "#extract" do
    it "extracts metazone mapping data to YAML" do
      extractor.extract

      output_file = output_dir + "metazone_mapping.yml"
      expect(output_file.exist?).to be true

      data = YAML.load_file(output_file)
      expect(data).to have_key("timezone_to_metazone")
      expect(data).to have_key("metazone_to_timezones")
      expect(data["timezone_to_metazone"]).to be_a(Hash)
      expect(data["metazone_to_timezones"]).to be_a(Hash)

      # Check for some known timezone -> metazone mappings from fixtures
      timezone_to_metazone = data["timezone_to_metazone"]
      expect(timezone_to_metazone).to include("America/New_York" => "America_Eastern")
      expect(timezone_to_metazone).to include("Europe/London" => "GMT")

      # Check reverse mapping
      metazone_to_timezones = data["metazone_to_timezones"]
      expect(metazone_to_timezones["America_Eastern"]).to include("America/New_York")
      expect(metazone_to_timezones["GMT"]).to include("Europe/London")
    end

    it "returns metazone mapping data" do
      result = extractor.extract

      expect(result).to have_key("timezone_to_metazone")
      expect(result).to have_key("metazone_to_timezones")
      expect(result["timezone_to_metazone"]).to be_a(Hash)
      expect(result["metazone_to_timezones"]).to be_a(Hash)
    end
  end

  describe "private methods" do
    describe "#extract_metazone_mapping" do
      it "extracts timezone to metazone mappings" do
        timezone_to_metazone = extractor.__send__(:extract_metazone_mapping)

        expect(timezone_to_metazone).to be_a(Hash)
        expect(timezone_to_metazone).to include("America/New_York" => "America_Eastern")
        expect(timezone_to_metazone).to include("Europe/London" => "GMT")
      end
    end

    describe "#create_reverse_mapping" do
      let(:sample_mapping) do
        {
          "America/New_York" => "America_Eastern",
          "America/Chicago" => "America_Central",
          "America/Denver" => "America_Mountain"
        }
      end

      it "creates reverse mapping from timezone to metazone mapping" do
        reverse_mapping = extractor.__send__(:create_reverse_mapping, sample_mapping)

        expect(reverse_mapping).to be_a(Hash)
        expect(reverse_mapping["America_Eastern"]).to eq(["America/New_York"])
        expect(reverse_mapping["America_Central"]).to eq(["America/Chicago"])
        expect(reverse_mapping["America_Mountain"]).to eq(["America/Denver"])
      end

      it "handles multiple timezones mapping to the same metazone" do
        mapping_with_duplicates = sample_mapping.merge({
          "America/Detroit" => "America_Eastern",
          "America/Kentucky/Louisville" => "America_Eastern"
        })

        reverse_mapping = extractor.__send__(:create_reverse_mapping, mapping_with_duplicates)

        eastern_timezones = reverse_mapping["America_Eastern"]
        expect(eastern_timezones).to include("America/New_York")
        expect(eastern_timezones).to include("America/Detroit")
        expect(eastern_timezones).to include("America/Kentucky/Louisville")
        expect(eastern_timezones).to eq(eastern_timezones.sort)
      end
    end
  end
end
