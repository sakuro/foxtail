# frozen_string_literal: true

require "tmpdir"
require_relative "../../../../lib/foxtail/cldr/extractors/date_time_formats_extractor"

RSpec.describe Foxtail::CLDR::Extractors::DateTimeFormatsExtractor do
  let(:fixture_source_dir) { File.join(__dir__, "..", "..", "..", "fixtures", "cldr") }
  let(:temp_output_dir) { Dir.mktmpdir }
  let(:extractor) { Foxtail::CLDR::Extractors::DateTimeFormatsExtractor.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  before do
    # Stub log method to prevent output during tests
    allow(extractor).to receive(:log)
  end

  after do
    FileUtils.rm_rf(temp_output_dir)
  end

  describe "#extract_locale" do
    context "with root locale" do
      it "extracts datetime format data" do
        extractor.extract_locale("root")

        output_file = File.join(temp_output_dir, "root", "datetime_formats.yml")
        expect(File.exist?(output_file)).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("root")
        expect(data["datetime_formats"]).to be_a(Hash)
      end
    end

    context "with en locale" do
      it "extracts locale-specific datetime data" do
        extractor.extract_locale("en")

        output_file = File.join(temp_output_dir, "en", "datetime_formats.yml")
        expect(File.exist?(output_file)).to be true

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

        output_file = File.join(temp_output_dir, "ja", "datetime_formats.yml")
        expect(File.exist?(output_file)).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("ja")
        expect(data["datetime_formats"]).to be_a(Hash)
      end
    end
  end

  describe "#extract_all" do
    it "processes all locale files in fixtures" do
      extractor.extract_all

      # Should create files for root, en, ja
      %w[root en ja].each do |locale|
        output_file = File.join(temp_output_dir, locale, "datetime_formats.yml")
        expect(File.exist?(output_file)).to be true
      end
    end
  end
end
