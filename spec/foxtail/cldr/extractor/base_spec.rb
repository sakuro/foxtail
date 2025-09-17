# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Extractor::Base, type: :extractor do
  # Create a concrete test class since Base is abstract
  let(:test_extractor_class) do
    Class.new(Foxtail::CLDR::Extractor::Base) do
      # Define class name for data_filename generation (test_extractor.yml)
      def self.to_s = "TestExtractor"
    end
  end

  let(:extractor) { test_extractor_class.new(source_dir:, output_dir:) }

  describe "#initialize" do
    it "sets source and output directories" do
      expect(extractor.instance_variable_get(:@source_dir)).to eq(source_dir)
      expect(extractor.instance_variable_get(:@output_dir)).to eq(output_dir)
    end
  end

  describe "#inflector" do
    it "provides access to the inflector instance" do
      inflector = extractor.__send__(:inflector)
      expect(inflector).to respond_to(:underscore)
      expect(inflector).to respond_to(:demodulize)
    end
  end

  describe "#data_filename" do
    it "generates filename from class name" do
      filename = extractor.__send__(:data_filename)
      expect(filename).to eq("test_extractor.yml")
    end
  end

  describe "#should_skip_write?" do
    let(:file_path) { output_dir + "test.yml" }
    let(:yaml_data) { {"test" => "data", "generated_at" => "2023-01-01T00:00:00Z"} }

    context "when file doesn't exist" do
      it "returns false" do
        result = extractor.__send__(:should_skip_write?, file_path, yaml_data)
        expect(result).to be false
      end
    end

    context "when file exists with same content" do
      it "returns true" do
        file_path.write(yaml_data.to_yaml)
        result = extractor.__send__(:should_skip_write?, file_path, yaml_data)
        expect(result).to be true
      end
    end

    context "when file exists with different content" do
      it "returns false" do
        different_data = yaml_data.merge("different" => "value")
        file_path.write(different_data.to_yaml)
        result = extractor.__send__(:should_skip_write?, file_path, yaml_data)
        expect(result).to be false
      end
    end

    context "when only generated_at differs" do
      it "returns true" do
        old_data = yaml_data.merge("generated_at" => "2022-01-01T00:00:00Z")
        file_path.write(old_data.to_yaml)
        result = extractor.__send__(:should_skip_write?, file_path, yaml_data)
        expect(result).to be true
      end
    end
  end
end
