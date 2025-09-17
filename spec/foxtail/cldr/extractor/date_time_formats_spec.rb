# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::DateTimeFormats, type: :extractor do
  let(:extractor) { Foxtail::CLDR::Extractor::DateTimeFormats.new(source_dir:, output_dir:) }

  before do
    # Setup fixture source directory
    setup_extractor_fixture(%w[root.xml en.xml ja.xml supplementalData.xml plurals.xml])

    # Setup parent_locales fixture
    setup_parent_locales_fixture
  end

  describe "#extract_locale" do
    context "with root locale" do
      it "extracts datetime format data" do
        extractor.extract_locale("root")

        output_file = output_dir + "root" + "datetime_formats.yml"
        expect(output_file.exist?).to be true

        data = YAML.load_file(output_file)
        expect(data["locale"]).to eq("root")
        expect(data["datetime_formats"]).to be_a(Hash)
      end
    end

    context "with en locale" do
      it "extracts locale-specific datetime data" do
        extractor.extract_locale("en")

        output_file = output_dir + "en" + "datetime_formats.yml"
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

        output_file = output_dir + "ja" + "datetime_formats.yml"
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
        output_file = output_dir + locale + "datetime_formats.yml"
        expect(output_file.exist?).to be true
      end
    end
  end
end
