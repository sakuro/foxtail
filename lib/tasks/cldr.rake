# frozen_string_literal: true

require "fileutils"
require "rake/clean"
require "shellwords"
require_relative "../foxtail/cldr/extractors/datetime_formats_extractor"
require_relative "../foxtail/cldr/extractors/number_formats_extractor"
require_relative "../foxtail/cldr/extractors/plural_rules_extractor"

# CLDR version configuration
CLDR_VERSION = "46"
CLDR_CORE_URL = "https://unicode.org/Public/cldr/#{CLDR_VERSION}/core.zip".freeze

# Define paths
PROJECT_ROOT = File.expand_path("../..", __dir__)
TMP_DIR = File.join(PROJECT_ROOT, "tmp")
DATA_DIR = File.join(PROJECT_ROOT, "data", "cldr")
CLDR_ZIP_PATH = File.join(TMP_DIR, "cldr-core.zip")
CLDR_EXTRACT_DIR = File.join(TMP_DIR, "cldr-core")

# Output file lists
PLURAL_RULES_FILES = FileList[File.join(DATA_DIR, "*/plural_rules.yml")]
NUMBER_FORMATS_FILES = FileList[File.join(DATA_DIR, "*/number_formats.yml")]
DATETIME_FORMATS_FILES = FileList[File.join(DATA_DIR, "*/datetime_formats.yml")]

# Clean tasks
CLEAN.include(CLDR_EXTRACT_DIR)
CLOBBER.include(CLDR_ZIP_PATH, PLURAL_RULES_FILES, NUMBER_FORMATS_FILES, DATETIME_FORMATS_FILES)

namespace :cldr do
  desc "Download CLDR core data to tmp directory"
  task :download do
    if Dir.exist?(CLDR_EXTRACT_DIR)
      puts "CLDR core data already exists at #{CLDR_EXTRACT_DIR}"
      puts "Remove the directory to re-download."
      next
    end

    # Create tmp directory if it doesn't exist
    FileUtils.mkdir_p(TMP_DIR)

    puts "Downloading CLDR core data..."

    # Download with curl using shelljoin for safety
    curl_cmd = ["curl", "-L", "-o", CLDR_ZIP_PATH, CLDR_CORE_URL]
    sh Shellwords.join(curl_cmd)

    puts "Extracting CLDR core data..."

    # Create extraction directory
    FileUtils.mkdir_p(CLDR_EXTRACT_DIR)

    # Extract with unzip
    unzip_cmd = ["unzip", "-q", "-o", CLDR_ZIP_PATH, "-d", CLDR_EXTRACT_DIR]
    sh Shellwords.join(unzip_cmd)

    puts "CLDR core data extracted to #{CLDR_EXTRACT_DIR}"
  end

  desc "Extract all CLDR data (uses rake task dependencies)"
  task extract: %i[extract:plural_rules extract:number_formats extract:datetime_formats]

  namespace :extract do
    desc "Extract CLDR data for a specific locale"
    task :locale, [:locale_id] => :download do |_task, args|
      unless args[:locale_id]
        puts "Usage: rake cldr:extract:locale[locale_id]"
        puts "Example: rake cldr:extract:locale[en]"
        exit 1
      end

      # Extract each data type for the specific locale
      extractors = [
        Foxtail::CLDR::Extractors::PluralRulesExtractor.new(
          source_dir: CLDR_EXTRACT_DIR,
          output_dir: DATA_DIR
        ),
        Foxtail::CLDR::Extractors::NumberFormatsExtractor.new(
          source_dir: CLDR_EXTRACT_DIR,
          output_dir: DATA_DIR
        ),
        Foxtail::CLDR::Extractors::DateTimeFormatsExtractor.new(
          source_dir: CLDR_EXTRACT_DIR,
          output_dir: DATA_DIR
        )
      ]

      extractors.each {|extractor| extractor.extract_locale(args[:locale_id]) }
    end

    desc "Extract CLDR plural rules from downloaded CLDR core data"
    task plural_rules: :download do
      # Clean up existing plural_rules files
      if PLURAL_RULES_FILES.any?
        puts "Cleaning up #{PLURAL_RULES_FILES.size} existing plural_rules files..."
        rm PLURAL_RULES_FILES
      end

      extractor = Foxtail::CLDR::Extractors::PluralRulesExtractor.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: DATA_DIR
      )

      extractor.extract_all
    end

    desc "Extract CLDR number formats from downloaded CLDR core data"
    task number_formats: :download do
      # Clean up existing number_formats files
      if NUMBER_FORMATS_FILES.any?
        puts "Cleaning up #{NUMBER_FORMATS_FILES.size} existing number_formats files..."
        rm NUMBER_FORMATS_FILES
      end

      extractor = Foxtail::CLDR::Extractors::NumberFormatsExtractor.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: DATA_DIR
      )

      extractor.extract_all
    end

    desc "Extract CLDR datetime formats from downloaded CLDR core data"
    task datetime_formats: :download do
      # Clean up existing datetime_formats files
      if DATETIME_FORMATS_FILES.any?
        puts "Cleaning up #{DATETIME_FORMATS_FILES.size} existing datetime_formats files..."
        rm DATETIME_FORMATS_FILES
      end

      extractor = Foxtail::CLDR::Extractors::DateTimeFormatsExtractor.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: DATA_DIR
      )

      extractor.extract_all
    end
  end

  desc "Extract CLDR plural rules (alias for cldr:extract:plural_rules)"
  task plural_rules: "extract:plural_rules"

  desc "Extract CLDR number formats (alias for cldr:extract:number_formats)"
  task number_formats: "extract:number_formats"

  desc "Extract CLDR datetime formats (alias for cldr:extract:datetime_formats)"
  task datetime_formats: "extract:datetime_formats"
end
