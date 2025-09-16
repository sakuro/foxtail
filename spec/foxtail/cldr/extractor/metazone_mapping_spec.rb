# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::MetazoneMapping do
  let(:fixture_source_dir) { Pathname(Dir.tmpdir) + "test_metazone_mapping_source" }
  let(:temp_output_dir) { Pathname(Dir.mktmpdir) }
  let(:extractor) { Foxtail::CLDR::Extractor::MetazoneMapping.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  before do
    # Setup fixture source directory with metaZones.xml
    setup_metazone_mapping_fixture(fixture_source_dir)
  end

  after do
    FileUtils.rm_rf(temp_output_dir)
    FileUtils.rm_rf(fixture_source_dir)
  end

  describe "#extract" do
    it "extracts metazone mapping data to YAML" do
      extractor.extract

      output_file = temp_output_dir + "metazone_mapping.yml"
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

  describe "extract with skip logic" do
    let(:file_path) { temp_output_dir + "metazone_mapping.yml" }

    context "when file does not exist" do
      it "writes the file" do
        expect(file_path.exist?).to be false

        extractor.extract

        expect(file_path.exist?).to be true
        content = YAML.load_file(file_path)
        expect(content["timezone_to_metazone"]).to include("America/New_York" => "America_Eastern")
      end
    end

    context "when file exists with same content" do
      before do
        # Allow info and debug logging throughout the test
        allow(Foxtail::CLDR.logger).to receive(:info)
        allow(Foxtail::CLDR.logger).to receive(:debug)
      end

      let(:initial_mtime) do
        # Write initial file
        extractor.extract
        sleep(0.01) # Wait to ensure mtime would change if file is rewritten
        file_path.mtime
      end

      it "skips writing when only generated_at would differ" do
        initial_mtime # Ensure file exists with recorded mtime

        result = extractor.extract

        # File modification time should not change when skipping
        expect(file_path.mtime).to eq(initial_mtime)

        # But should still return the data
        expect(result["timezone_to_metazone"]).to include("America/New_York" => "America_Eastern")

        # Should have logged info messages 4 times total:
        # - 2 from initial write (Extracting... and complete)
        # - 2 from second call (Extracting... and complete, even when skipping file write)
        expect(Foxtail::CLDR.logger).to have_received(:info).exactly(4).times
      end
    end

    context "when CLDR version changes" do
      let(:initial_mtime) do
        # Write initial file
        extractor.extract
        sleep(0.01) # Wait to ensure mtime would change
        file_path.mtime
      end

      it "overwrites the file when CLDR version differs" do
        initial_mtime # Ensure file exists with recorded mtime

        # Change CLDR version
        stub_const("Foxtail::CLDR::SOURCE_VERSION", "47")

        extractor.extract

        # File should be updated
        expect(file_path.mtime).to be > initial_mtime

        content = YAML.load_file(file_path)
        expect(content["cldr_version"]).to eq("47")
      end
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
