# frozen_string_literal: true

require "tmpdir"

RSpec.describe Foxtail::CLDR::Extractor::LocaleAliases do
  let(:fixture_source_dir) { Pathname(Dir.tmpdir) + "test_locale_aliases_source" }
  let(:temp_output_dir) { Pathname(Dir.mktmpdir) }
  let(:extractor) { Foxtail::CLDR::Extractor::LocaleAliases.new(source_dir: fixture_source_dir, output_dir: temp_output_dir) }

  before do
    # Setup fixture source directory
    setup_locale_aliases_fixture(fixture_source_dir)
  end

  after do
    FileUtils.rm_rf(temp_output_dir)
    FileUtils.rm_rf(fixture_source_dir)
  end

  describe "#extract" do
    it "extracts locale aliases from fixture files" do
      extractor.extract

      output_file = temp_output_dir + "locale_aliases.yml"
      expect(output_file.exist?).to be true

      data = YAML.load_file(output_file)
      expect(data["locale_aliases"]).to be_a(Hash)
      expect(data["locale_aliases"]).not_to be_empty
    end

    it "includes zh_TW -> zh_Hant_TW mapping" do
      extractor.extract

      output_file = temp_output_dir + "locale_aliases.yml"
      data = YAML.load_file(output_file)

      expect(data["locale_aliases"]).to include("zh_TW" => "zh_Hant_TW")
    end
  end

  describe "private methods" do
    describe "#load_traditional_aliases" do
      it "loads from supplementalMetadata.xml" do
        aliases = extractor.__send__(:load_traditional_aliases)

        expect(aliases).to be_a(Hash)
        expect(aliases).not_to be_empty
      end
    end

    describe "#load_likely_subtag_aliases" do
      it "loads from likelySubtags.xml" do
        aliases = extractor.__send__(:load_likely_subtag_aliases)

        expect(aliases).to be_a(Hash)
        expect(aliases).to include("zh_TW" => "zh_Hant_TW")
      end
    end
  end

  describe "extract with skip logic" do
    let(:test_aliases) do
      {
        "zh_TW" => "zh_Hant_TW",
        "no_NO" => "nb_NO"
      }
    end
    let(:file_path) { temp_output_dir + "locale_aliases.yml" }

    context "when file does not exist" do
      it "writes the file" do
        expect(file_path.exist?).to be false

        data = {"locale_aliases" => test_aliases}
        extractor.__send__(:write_single_file, "locale_aliases.yml", data)

        expect(file_path.exist?).to be true
        content = YAML.load_file(file_path)
        expect(content["locale_aliases"]).to eq(test_aliases)
      end
    end

    context "when file exists with same content" do
      before do
        # Allow debug logging throughout the test
        allow(Foxtail::CLDR.logger).to receive(:debug)
      end

      let(:initial_mtime) do
        # Write initial file
        data = {"locale_aliases" => test_aliases}
        extractor.__send__(:write_single_file, "locale_aliases.yml", data)
        sleep(0.01) # Wait to ensure mtime would change if file is rewritten
        file_path.mtime
      end

      it "skips writing when only generated_at would differ" do
        initial_mtime # Ensure file exists with recorded mtime

        data = {"locale_aliases" => test_aliases}
        extractor.__send__(:write_single_file, "locale_aliases.yml", data)

        # File modification time should not change when skipping
        expect(file_path.mtime).to eq(initial_mtime)

        # Should have logged exactly once (from initial write in let block)
        expect(Foxtail::CLDR.logger).to have_received(:debug).once
      end
    end

    context "when file exists with different content" do
      let(:old_aliases) do
        {
          "old_alias" => "old_target"
        }
      end

      let(:initial_mtime) do
        # Write initial file with different content
        old_data = {"locale_aliases" => old_aliases}
        extractor.__send__(:write_single_file, "locale_aliases.yml", old_data)
        sleep(0.01) # Wait to ensure mtime would change
        file_path.mtime
      end

      it "overwrites the file when content differs" do
        initial_mtime # Ensure file exists with recorded mtime

        data = {"locale_aliases" => test_aliases}
        extractor.__send__(:write_single_file, "locale_aliases.yml", data)

        # File should be updated
        expect(file_path.mtime).to be > initial_mtime

        content = YAML.load_file(file_path)
        expect(content["locale_aliases"]).to eq(test_aliases)
        expect(content["locale_aliases"]["old_alias"]).to be_nil
      end
    end
  end
end
