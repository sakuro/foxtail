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

  describe "extract_all with skip logic" do
    let(:file_path) { File.join(temp_output_dir, "parent_locales.yml") }

    context "when file does not exist" do
      it "writes the file" do
        expect(File.exist?(file_path)).to be false

        extractor.extract_all

        expect(File.exist?(file_path)).to be true
        content = YAML.load_file(file_path)
        expect(content["parent_locales"]).to include("en_AU" => "en_001")
      end
    end

    context "when file exists with same content" do
      let(:initial_mtime) do
        # Write initial file
        extractor.extract_all
        sleep(0.01) # Wait to ensure mtime would change if file is rewritten
        File.mtime(file_path)
      end

      it "skips writing when only generated_at would differ" do
        allow(Foxtail::CLDR.logger).to receive(:debug)
        initial_mtime # Ensure file exists with recorded mtime

        result = extractor.extract_all

        # File modification time should not change
        expect(File.mtime(file_path)).to eq(initial_mtime)
        expect(Foxtail::CLDR.logger).to have_received(:debug).with(/Skipping.*only generated_at differs/)

        # But should still return the data
        expect(result["parent_locales"]).to include("en_AU" => "en_001")
      end
    end

    context "when CLDR version changes" do
      let(:initial_mtime) do
        # Write initial file
        extractor.extract_all
        sleep(0.01) # Wait to ensure mtime would change
        File.mtime(file_path)
      end

      it "overwrites the file when CLDR version differs" do
        initial_mtime # Ensure file exists with recorded mtime

        # Change CLDR version
        allow(ENV).to receive(:fetch).with("CLDR_VERSION", "46").and_return("47")

        extractor.extract_all

        # File should be updated
        expect(File.mtime(file_path)).to be > initial_mtime

        content = YAML.load_file(file_path)
        expect(content["cldr_version"]).to eq("47")
      end
    end
  end
end
