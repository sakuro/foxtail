# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractors::BaseExtractor do
  # Create a concrete test class since BaseExtractor is abstract
  let(:test_extractor_class) do
    Class.new(described_class) do
      def data_type_name
        "test data"
      end

      def extract_data_from_xml(_xml_doc)
        {"test_key" => "test_value"}
      end

      def data?(data)
        data.is_a?(Hash) && !data.empty?
      end

      def write_data(locale_id, data)
        write_yaml_file(locale_id, "test_data.yml", data)
      end
    end
  end

  let(:test_source_dir) { File.join(Dir.tmpdir, "test_cldr_source") }
  let(:test_output_dir) { File.join(Dir.tmpdir, "test_cldr_output") }
  let(:extractor) { test_extractor_class.new(source_dir: test_source_dir, output_dir: test_output_dir) }

  before do
    # Stub log method to prevent output during tests
    allow(extractor).to receive(:log)
    # Create test directory structure
    FileUtils.mkdir_p(File.join(test_source_dir, "common", "main"))
    FileUtils.mkdir_p(test_output_dir)
  end

  after do
    # Clean up test directories
    FileUtils.rm_rf(test_source_dir)
    FileUtils.rm_rf(test_output_dir)
  end

  describe "#initialize" do
    it "sets source and output directories" do
      expect(extractor.source_dir).to eq(test_source_dir)
      expect(extractor.output_dir).to eq(test_output_dir)
    end
  end

  describe "#extract_all" do
    before do
      # Create test XML files
      %w[en fr de].each do |locale|
        xml_content = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <ldml>
            <identity>
              <language type="#{locale}"/>
            </identity>
          </ldml>
        XML

        File.write(File.join(test_source_dir, "common", "main", "#{locale}.xml"), xml_content)
      end
    end

    it "processes all locale files" do
      allow(extractor).to receive(:log)
      extractor.extract_all
      expect(extractor).to have_received(:log).with("Extracting test data from 3 locales...")
      expect(extractor).to have_received(:log).with("test data extraction complete")
    end

    it "creates output files for each locale" do
      extractor.extract_all

      %w[en fr de].each do |locale|
        file_path = File.join(test_output_dir, locale, "test_data.yml")
        expect(File.exist?(file_path)).to be true
      end
    end
  end

  describe "#extract_locale" do
    let(:test_xml_content) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8" ?>
        <ldml>
          <identity>
            <language type="en"/>
          </identity>
        </ldml>
      XML
    end

    context "when locale file exists" do
      before do
        File.write(File.join(test_source_dir, "common", "main", "en.xml"), test_xml_content)
      end

      it "extracts locale data successfully" do
        expect { extractor.extract_locale("en") }.not_to raise_error
      end

      it "creates output file" do
        extractor.extract_locale("en")
        file_path = File.join(test_output_dir, "en", "test_data.yml")

        expect(File.exist?(file_path)).to be true

        # Verify file content has metadata
        content = YAML.load_file(file_path)
        expect(content["locale"]).to eq("en")
        expect(content["generated_at"]).not_to be_nil
        expect(content["cldr_version"]).to eq("46")
        expect(content["test_key"]).to eq("test_value")
      end
    end

    context "when extracted data is empty" do
      let(:empty_extractor_class) do
        Class.new(described_class) do
          def data_type_name
            "empty data"
          end

          def extract_data_from_xml(_xml_doc)
            {}
          end

          def data?(_data)
            false
          end

          def write_data(locale_id, data)
            write_yaml_file(locale_id, "empty_data.yml", data)
          end
        end
      end

      it "does not create output file when data? returns false" do
        empty_extractor = empty_extractor_class.new(source_dir: test_source_dir, output_dir: test_output_dir)
        allow(empty_extractor).to receive(:log) # Stub log for empty_extractor too
        File.write(File.join(test_source_dir, "common", "main", "en.xml"), test_xml_content)

        empty_extractor.extract_locale("en")

        file_path = File.join(test_output_dir, "en", "empty_data.yml")
        expect(File.exist?(file_path)).to be false
      end
    end
  end

  describe "abstract methods" do
    let(:abstract_extractor) { Foxtail::CLDR::Extractors::BaseExtractor.new(source_dir: test_source_dir, output_dir: test_output_dir) }

    it "raises NotImplementedError for data_type_name" do
      expect { abstract_extractor.__send__(:data_type_name) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for extract_data_from_xml" do
      doc = REXML::Document.new("<test/>")
      expect { abstract_extractor.__send__(:extract_data_from_xml, doc) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for data?" do
      expect { abstract_extractor.__send__(:data?, {}) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for write_data" do
      expect { abstract_extractor.__send__(:write_data, "en", {}) }.to raise_error(NotImplementedError)
    end
  end

  describe "validation" do
    context "when source directory is invalid" do
      it "raises ArgumentError if source directory does not exist" do
        bad_extractor = test_extractor_class.new(
          source_dir: "/nonexistent/path",
          output_dir: test_output_dir
        )

        expect { bad_extractor.extract_all }
          .to raise_error(ArgumentError, /CLDR source directory not found/)
      end
    end
  end
end
