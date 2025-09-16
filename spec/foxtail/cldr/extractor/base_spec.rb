# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::Base do
  # Create a concrete test class since BaseExtractor is abstract
  let(:test_extractor_class) do
    Class.new(described_class) do
      def self.name
        "TestExtractor"
      end

      def extract_data_from_xml(_xml_doc)
        {"test_key" => "test_value"}
      end

      def data?(data)
        data.is_a?(Hash) && !data.empty?
      end

      def write_data(locale_id, data)
        write_yaml_file(locale_id, "test_extractor.yml", data)
      end
    end
  end

  let(:test_source_dir) { Pathname(Dir.tmpdir) + "test_cldr_source" }
  let(:test_output_dir) { Pathname(Dir.tmpdir) + "test_cldr_output" }
  let(:extractor) { test_extractor_class.new(source_dir: test_source_dir, output_dir: test_output_dir) }

  before do
    # Setup test directory structure with fixtures
    test_output_dir.mkpath
    setup_extractor_test_fixture(test_source_dir)

    # Create parent_locales.yml for Extractor tests
    create_parent_locales_file
  end

  def create_parent_locales_file
    parent_locales_data = {
      "parent_locales" => {
        "en_AU" => "en_001",
        "en_001" => "en",
        "es_MX" => "es_419"
      }
    }
    (test_output_dir + "parent_locales.yml").write(parent_locales_data.to_yaml)
  end

  after do
    # Clean up test directories
    FileUtils.rm_rf(test_source_dir)
    FileUtils.rm_rf(test_output_dir)
  end

  describe "#initialize" do
    it "sets source and output directories" do
      expect(extractor.source_dir).to eq(Pathname(test_source_dir))
      expect(extractor.output_dir).to eq(Pathname(test_output_dir))
    end
  end

  describe "#extract_all" do
    it "processes all locale files" do
      extractor.extract_all
      expect(Foxtail::CLDR.logger).to have_received(:info).with("Extracting TestExtractor from 3 locales...")
      expect(Foxtail::CLDR.logger).to have_received(:info).with("TestExtractor extraction complete (3 locales)")
    end

    it "creates output files for each locale" do
      extractor.extract_all

      %w[en fr de].each do |locale|
        file_path = test_output_dir + locale + "test_extractor.yml"
        expect(file_path.exist?).to be true
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
      it "extracts locale data successfully" do
        expect { extractor.extract_locale("en") }.not_to raise_error
      end

      it "creates output file" do
        extractor.extract_locale("en")
        file_path = test_output_dir + "en" + "test_extractor.yml"

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

        empty_extractor.extract_locale("en")

        file_path = test_output_dir + "en" + "empty_data.yml"
        expect(file_path.exist?).to be false
      end
    end

    context "when parent_locales.yml is missing" do
      before do
        # Remove parent_locales.yml to test error handling
        (test_output_dir + "parent_locales.yml").delete if (test_output_dir + "parent_locales.yml").exist?
      end

      it "raises ArgumentError with appropriate message" do
        expect {
          extractor.extract_locale("en")
        }.to raise_error(ArgumentError, /Parent locales data not found.*Run parent locales extraction first/)
      end
    end
  end

  describe "abstract methods" do
    let(:abstract_extractor) { Foxtail::CLDR::Extractor::Base.new(source_dir: test_source_dir, output_dir: test_output_dir) }

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

  describe "#should_skip_write?" do
    let(:file_path) { test_output_dir + "test_file.yml" }

    context "when file does not exist" do
      it "returns false" do
        expect(extractor.__send__(:should_skip_write?, file_path, {})).to be false
      end
    end

    context "when file exists" do
      let(:existing_data) do
        {
          "locale" => "en",
          "generated_at" => "2023-01-01T00:00:00Z",
          "cldr_version" => Foxtail::CLDR::SOURCE_VERSION,
          "test_key" => "test_value"
        }
      end

      before do
        file_path.write(existing_data.to_yaml)
      end

      context "when only generated_at differs" do
        let(:new_data) do
          {
            "locale" => "en",
            "generated_at" => "2023-12-31T23:59:59Z",
            "cldr_version" => Foxtail::CLDR::SOURCE_VERSION,
            "test_key" => "test_value"
          }
        end

        it "returns true" do
          expect(extractor.__send__(:should_skip_write?, file_path, new_data)).to be true
        end
      end

      context "when data content differs" do
        let(:new_data) do
          {
            "locale" => "en",
            "generated_at" => "2023-12-31T23:59:59Z",
            "cldr_version" => Foxtail::CLDR::SOURCE_VERSION,
            "test_key" => "different_value"
          }
        end

        it "returns false" do
          expect(extractor.__send__(:should_skip_write?, file_path, new_data)).to be false
        end
      end

      context "when new field is added" do
        let(:new_data) do
          {
            "locale" => "en",
            "generated_at" => "2023-12-31T23:59:59Z",
            "cldr_version" => Foxtail::CLDR::SOURCE_VERSION,
            "test_key" => "test_value",
            "new_field" => "new_value"
          }
        end

        it "returns false" do
          expect(extractor.__send__(:should_skip_write?, file_path, new_data)).to be false
        end
      end

      context "when existing file is corrupted" do
        before do
          file_path.write("invalid yaml content: [")
        end

        it "returns false" do
          expect(extractor.__send__(:should_skip_write?, file_path, existing_data)).to be false
        end
      end

      context "when existing file contains non-hash data" do
        before do
          file_path.write("just a string".to_yaml)
        end

        it "returns false" do
          expect(extractor.__send__(:should_skip_write?, file_path, existing_data)).to be false
        end
      end
    end
  end

  describe "write_yaml_file with skip logic" do
    let(:locale_id) { "en" }
    let(:filename) { "test_extractor.yml" }
    let(:test_data) { {"test_key" => "test_value"} }
    let(:file_path) { test_output_dir + locale_id + filename }

    context "when file does not exist" do
      it "writes the file" do
        expect(file_path.exist?).to be false

        extractor.__send__(:write_yaml_file, locale_id, filename, test_data)

        expect(file_path.exist?).to be true
        content = YAML.load_file(file_path)
        expect(content["test_key"]).to eq("test_value")
      end
    end

    context "when file exists with same content" do
      before do
        # Allow debug logging throughout the test
        allow(Foxtail::CLDR.logger).to receive(:debug)
      end

      let(:initial_mtime) do
        # Write initial file
        extractor.__send__(:write_yaml_file, locale_id, filename, test_data)
        sleep(0.01) # Wait to ensure mtime would change if file is rewritten
        file_path.mtime
      end

      it "skips writing when only generated_at would differ" do
        initial_mtime # Ensure file exists with recorded mtime

        extractor.__send__(:write_yaml_file, locale_id, filename, test_data)

        # File modification time should not change when skipping
        expect(file_path.mtime).to eq(initial_mtime)

        # Should have logged exactly once (from initial write in let block)
        expect(Foxtail::CLDR.logger).to have_received(:debug).once
      end
    end

    context "when file exists with different content" do
      let(:initial_mtime) do
        # Write initial file
        extractor.__send__(:write_yaml_file, locale_id, filename, {"old_key" => "old_value"})
        sleep(0.01) # Wait to ensure mtime would change
        file_path.mtime
      end

      it "overwrites the file when content differs" do
        initial_mtime # Ensure file exists with recorded mtime

        extractor.__send__(:write_yaml_file, locale_id, filename, test_data)

        # File should be updated
        expect(file_path.mtime).to be > initial_mtime

        content = YAML.load_file(file_path)
        expect(content["test_key"]).to eq("test_value")
        expect(content["old_key"]).to be_nil
      end
    end
  end
end
