# frozen_string_literal: true

# Shared context for CLDR extractor tests providing complete test infrastructure
#
# This context provides everything needed for extractor tests:
# - Automatic directory management (source_dir, output_dir)
# - CLDR fixture setup with proper directory structure
# - Parent locales YAML fixture setup
# - Automatic cleanup after each test
#
# Usage:
#   RSpec.describe Foxtail::CLDR::Extractor::SomeExtractor, type: :extractor do
#     before do
#       setup_extractor_fixture(%w[root.xml en.xml supplementalData.xml])
#       setup_parent_locales_fixture
#     end
#   end
#
# Available methods:
# - setup_extractor_fixture(files)       - Setup XML fixtures in CLDR structure
# - setup_parent_locales_fixture         - Setup parent_locales.yml
#
# Available let variables:
# - source_dir    - Temporary directory for CLDR source files
# - output_dir    - Temporary directory for extractor output
# - fixtures_dir  - Path to CLDR fixture files directory
RSpec.shared_context "when using extractor directory management" do
  # Files that should be placed in the supplemental directory
  let(:supplemental_files) { %w[likelySubtags.xml plurals.xml metaZones.xml] }
  let(:fixtures_dir) { Pathname(__dir__).parent + "fixtures" + "cldr" }

  let(:source_dir) { Pathname(Dir.mktmpdir("rspec-extractor-source-")) }
  let(:output_dir) { Pathname(Dir.mktmpdir("rspec-extractor-output-")) }

  before do
    # Ensure both directories exist
    source_dir.mkpath
    output_dir.mkpath
  end

  after do
    # Clean up test directories
    FileUtils.rm_rf(output_dir)
    FileUtils.rm_rf(source_dir)
  end

  # Setup extractor fixture files with CLDR directory structure
  # @param files [Array<String>] List of fixture files to copy
  def setup_extractor_fixture(files)
    # Copy specified fixture files
    files.each do |file|
      source_path = fixtures_dir + file

      # Determine destination based on file type
      dest_dir = source_dir + "common" + (file.include?("supplemental") || supplemental_files.include?(file) ? "supplemental" : "main")
      dest_dir.mkpath
      base_name = Pathname(file).basename(".xml").to_s.sub(/^test_/, "")
      dest_path = dest_dir + "#{base_name}.xml"

      FileUtils.cp(source_path, dest_path)
    end
  end

  # Setup parent locales fixture for extractor tests
  def setup_parent_locales_fixture
    # Copy parent_locales.yml to the output directory (not source directory)
    fixture_path = fixtures_dir + "parent_locales.yml"
    output_path = output_dir + "parent_locales.yml"

    # Copy the fixture file
    FileUtils.cp(fixture_path, output_path)
  end
end
