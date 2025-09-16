# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::DateTimeFormats do
  let(:fixture_source_dir) { Pathname(Dir.tmpdir) + "test_datetime_formats_source" }
  let(:temp_output_dir) { Pathname(Dir.mktmpdir) }
  let(:extractor) { Foxtail::CLDR::Extractor::DateTimeFormats.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

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
        "es_MX" => "es_419"
      }
    }
    (temp_output_dir + "parent_locales.yml").write(parent_locales_data.to_yaml)
  end

  describe "#extract_locale" do
    context "with root locale" do
      it "extracts datetime format data" do
        extractor.extract_locale("root")

        output_file = temp_output_dir + "root" + "datetime_formats.yml"
        expect(output_file.exist?).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("root")
        expect(data["datetime_formats"]).to be_a(Hash)
      end
    end

    context "with en locale" do
      it "extracts locale-specific datetime data" do
        extractor.extract_locale("en")

        output_file = temp_output_dir + "en" + "datetime_formats.yml"
        expect(output_file.exist?).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("en")
        expect(data["datetime_formats"]).to be_a(Hash)

        # Should have months and days
        if data["datetime_formats"]["months"]
          expect(data["datetime_formats"]["months"]).to be_a(Hash)
        end

        if data["datetime_formats"]["days"]
          expect(data["datetime_formats"]["days"]).to be_a(Hash)
        end
      end
    end

    context "with ja locale" do
      it "extracts Japanese datetime data" do
        extractor.extract_locale("ja")

        output_file = temp_output_dir + "ja" + "datetime_formats.yml"
        expect(output_file.exist?).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("ja")
        expect(data["datetime_formats"]).to be_a(Hash)
      end
    end
  end

  describe "#extract" do
    it "processes all locale files in fixtures" do
      extractor.extract

      # Should create files for root, en, ja
      %w[root en ja].each do |locale|
        output_file = temp_output_dir + locale + "datetime_formats.yml"
        expect(output_file.exist?).to be true
      end
    end
  end
end
