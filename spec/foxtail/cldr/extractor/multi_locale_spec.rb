# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::MultiLocale, type: :extractor do
  # Create a concrete test class since MultiLocale is abstract
  let(:test_extractor_class) do
    Class.new(Foxtail::CLDR::Extractor::MultiLocale) do
      # Define class name for data_filename generation (test_extractor.yml)
      def self.to_s = "TestExtractor"

      def extract_data_from_xml(_xml_doc)
        {"test_key" => "test_value"}
      end

      def data?(data)
        data.is_a?(Hash) && !data.empty?
      end
    end
  end

  let(:extractor) { test_extractor_class.new(source_dir:, output_dir:) }

  before do
    # Setup test directory structure with fixtures
    setup_extractor_fixture(%w[en.xml fr.xml de.xml])

    # Setup parent_locales fixture
    setup_parent_locales_fixture
  end

  describe "#initialize" do
    it "sets source and output directories" do
      expect(extractor.source_dir).to eq(Pathname(source_dir))
      expect(extractor.output_dir).to eq(Pathname(output_dir))
    end
  end

  describe "#extract" do
    it "processes all locale files" do
      extractor.extract
      expect(Foxtail::CLDR.logger).to have_received(:info).with("Extracting TestExtractor from 3 locales...")
      expect(Foxtail::CLDR.logger).to have_received(:info).with("TestExtractor extraction complete (3 locales)")
    end

    it "creates output files for each locale" do
      extractor.extract

      %w[en fr de].each do |locale|
        file_path = output_dir + locale + "test_extractor.yml"
        expect(file_path.exist?).to be true
      end
    end
  end

  describe "#extract_locale" do
    context "when locale file exists" do
      it "extracts locale data successfully" do
        expect { extractor.extract_locale("en") }.not_to raise_error
      end

      it "creates output file" do
        extractor.extract_locale("en")
        file_path = output_dir + "en" + "test_extractor.yml"

        expect(file_path.exist?).to be true

        # Verify file content has metadata
        content = YAML.load_file(file_path)
        expect(content["locale"]).to eq("en")
        expect(content["generated_at"]).not_to be_nil
        expect(content["cldr_version"]).to eq(Foxtail::CLDR::SOURCE_VERSION)
        expect(content["test_key"]).to eq("test_value")
      end
    end

    context "when extracted data is empty" do
      let(:empty_extractor_class) do
        Class.new(Foxtail::CLDR::Extractor::MultiLocale) do
          def self.name
            "EmptyExtractor"
          end

          def data_type_name
            "empty data"
          end

          def extract_data_from_xml(_xml_doc)
            {}
          end

          def data?(_data)
            false
          end
        end
      end

      it "does not create output file when data? returns false" do
        empty_extractor = empty_extractor_class.new(source_dir:, output_dir:)

        empty_extractor.extract_locale("en")

        file_path = output_dir + "en" + "empty_data.yml"
        expect(file_path.exist?).to be false
      end
    end

    context "when parent_locales.yml is missing" do
      before do
        # Remove parent_locales.yml to test error handling
        (output_dir + "parent_locales.yml").delete if (output_dir + "parent_locales.yml").exist?
      end

      it "raises ArgumentError with appropriate message" do
        expect {
          extractor.extract_locale("en")
        }.to raise_error(ArgumentError, /Parent locales data not found.*Run parent locales extraction first/)
      end
    end
  end

  describe "abstract methods" do
    let(:abstract_extractor) { Foxtail::CLDR::Extractor::MultiLocale.new(source_dir:, output_dir:) }

    it "raises NotImplementedError for extract_data_from_xml" do
      doc = REXML::Document.new("<test/>")
      expect { abstract_extractor.__send__(:extract_data_from_xml, doc) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for data?" do
      expect { abstract_extractor.__send__(:data?, {}) }.to raise_error(NotImplementedError)
    end
  end

  describe "extract_locale with skip logic" do
    let(:locale_id) { "en" }
    let(:output_file) { output_dir + locale_id + "test_extractor.yml" }

    before do
      output_file.delete if output_file.exist?
    end

    context "when file does not exist" do
      it "creates the file" do
        expect { extractor.extract_locale(locale_id) }
          .to change(output_file, :exist?).from(false).to(true)
      end
    end

    context "when file exists with same content" do
      let!(:initial_mtime) do
        extractor.extract_locale(locale_id)
        sleep(0.01)
        output_file.mtime
      end

      it "skips writing when content would be identical" do
        extractor.extract_locale(locale_id)

        # File should not be modified
        expect(output_file.mtime).to eq(initial_mtime)
      end
    end

    context "when file exists with different content" do
      before do
        # Stub to return different content on successive calls
        allow(extractor).to receive(:data?).and_return(true)
        allow(extractor).to receive(:extract_locale_with_inheritance)
          .and_return({"old_key" => "old_value"}, {"new_key" => "new_value"})
      end

      let!(:initial_mtime) do
        extractor.extract_locale(locale_id)
        sleep(0.01)
        output_file.mtime
      end

      it "overwrites the file when content differs" do
        extractor.extract_locale(locale_id)

        # File should be updated
        expect(output_file.mtime).to be > initial_mtime
      end
    end
  end
end
