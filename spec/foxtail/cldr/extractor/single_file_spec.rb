# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::SingleFile, type: :extractor do
  # Create a concrete test class since SingleFile is abstract
  let(:test_extractor_class) do
    Class.new(Foxtail::CLDR::Extractor::SingleFile) do
      # Define class name for data_filename generation (test_extractor.yml)
      def self.to_s = "TestExtractor"

      private def extract_data
        {"test_key" => "test_value"}
      end
    end
  end

  let(:extractor) { test_extractor_class.new(source_dir:, output_dir:) }

  before do
    setup_extractor_fixture(%w[supplementalData.xml])
  end

  describe "#extract" do
    it "extracts and writes single file data" do
      result = extractor.extract

      expect(result).to eq({"test_key" => "test_value"})

      output_file = output_dir + "test_extractor.yml"
      expect(output_file.exist?).to be true

      data = YAML.load_file(output_file)
      expect(data["test_key"]).to eq("test_value")
    end
  end

  describe "extract with skip logic" do
    let(:output_file) { output_dir + "test_extractor.yml" }

    before do
      output_file.delete if output_file.exist?
    end

    context "when file does not exist" do
      it "creates the file" do
        expect { extractor.extract }
          .to change(output_file, :exist?).from(false).to(true)
      end
    end

    context "when file exists with same content" do
      let!(:initial_mtime) do
        extractor.extract
        sleep(0.01)
        output_file.mtime
      end

      it "skips writing when content would be identical" do
        extractor.extract

        # File should not be modified
        expect(output_file.mtime).to eq(initial_mtime)
      end
    end

    context "when file exists with different content" do
      before do
        # Stub to return different content on successive calls
        allow(extractor).to receive(:extract_data)
          .and_return({"old_key" => "old_value"}, {"new_key" => "new_value"})
      end

      let!(:initial_mtime) do
        extractor.extract
        sleep(0.01)
        output_file.mtime
      end

      it "overwrites the file when content differs" do
        extractor.extract

        # File should be updated
        expect(output_file.mtime).to be > initial_mtime
      end
    end
  end
end
