# frozen_string_literal: true

require "fileutils"
require "foxtail"
require "pathname"
require "rake/clean"
require "shellwords"

# Task to set debug logging for CLDR operations
desc "Set debug logging level for CLDR operations"
task :set_debug_logging do
  Foxtail::CLDR.logger = Dry.Logger(:cldr, level: :debug)
end

# CLDR version configuration
CLDR_VERSION = "46"
CLDR_CORE_URL = "https://unicode.org/Public/cldr/#{CLDR_VERSION}/core.zip".freeze

# Define paths
TMP_DIR = Foxtail::ROOT + "tmp"
CLDR_ZIP_PATH = TMP_DIR + "cldr-core.zip"
CLDR_EXTRACT_DIR = TMP_DIR + "cldr-core"

# Output file lists
PLURAL_RULES_FILES = FileList[Foxtail.cldr_dir.glob("*/plural_rules.yml").map(&:to_s)]
NUMBER_FORMATS_FILES = FileList[Foxtail.cldr_dir.glob("*/number_formats.yml").map(&:to_s)]
CURRENCIES_FILES = FileList[Foxtail.cldr_dir.glob("*/currencies.yml").map(&:to_s)]
UNITS_FILES = FileList[Foxtail.cldr_dir.glob("*/units.yml").map(&:to_s)]
TIMEZONE_NAMES_FILES = FileList[Foxtail.cldr_dir.glob("*/timezone_names.yml").map(&:to_s)]
DATETIME_FORMATS_FILES = FileList[Foxtail.cldr_dir.glob("*/datetime_formats.yml").map(&:to_s)]
LOCALE_ALIASES_FILE = Foxtail.cldr_dir + "locale_aliases.yml"
PARENT_LOCALES_FILE = Foxtail.cldr_dir + "parent_locales.yml"

# Clean tasks
# CLEAN removes extracted CLDR source (can be re-extracted from zip)
CLEAN.include(CLDR_EXTRACT_DIR)
# CLOBBER removes generated CLDR data files
CLOBBER.include(
  PLURAL_RULES_FILES,
  NUMBER_FORMATS_FILES,
  CURRENCIES_FILES,
  UNITS_FILES,
  DATETIME_FORMATS_FILES,
  LOCALE_ALIASES_FILE,
  PARENT_LOCALES_FILE
)
CLOBBER.exclude((Foxtail.cldr_dir + "README.md").to_s)
# Keep the downloaded zip file to avoid re-downloading
CLOBBER.exclude(CLDR_ZIP_PATH)

namespace :cldr do
  desc "Download CLDR core data to tmp directory"
  task download: :set_debug_logging do
    if Dir.exist?(CLDR_EXTRACT_DIR)
      Foxtail::CLDR.logger.info "CLDR core data already exists at #{CLDR_EXTRACT_DIR}"
      Foxtail::CLDR.logger.info "Remove the directory to re-download."
      next
    end

    # Create tmp directory if it doesn't exist
    FileUtils.mkdir_p(TMP_DIR)

    Foxtail::CLDR.logger.info "Downloading CLDR core data..."

    # Download with curl using shelljoin for safety
    curl_cmd = ["curl", "-L", "-o", CLDR_ZIP_PATH, CLDR_CORE_URL]
    sh Shellwords.join(curl_cmd)

    Foxtail::CLDR.logger.info "Extracting CLDR core data..."

    # Create extraction directory
    FileUtils.mkdir_p(CLDR_EXTRACT_DIR)

    # Extract with unzip
    unzip_cmd = ["unzip", "-q", "-o", CLDR_ZIP_PATH, "-d", CLDR_EXTRACT_DIR]
    sh Shellwords.join(unzip_cmd)

    Foxtail::CLDR.logger.info "CLDR core data extracted to #{CLDR_EXTRACT_DIR}"
  end

  desc "Extract all CLDR data (uses rake task dependencies)"
  task extract: %i[
    extract:parent_locales
    extract:locale_aliases
    extract:metazone_mapping
    extract:plural_rules
    extract:number_formats
    extract:currencies
    extract:units
    extract:timezone_names
    extract:datetime_formats
  ]

  namespace :extract do
    desc "Extract CLDR parent locales from downloaded CLDR core data"
    task parent_locales: %i[set_debug_logging download] do
      extractor = Foxtail::CLDR::Extractor::ParentLocales.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end

    desc "Extract CLDR locale aliases from downloaded CLDR core data"
    task locale_aliases: %i[set_debug_logging download] do
      extractor = Foxtail::CLDR::Extractor::LocaleAliases.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end

    desc "Extract CLDR metazone mapping from downloaded CLDR core data"
    task metazone_mapping: %i[set_debug_logging download] do
      extractor = Foxtail::CLDR::Extractor::MetazoneMapping.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end

    desc "Extract CLDR data for a specific locale"
    task :locale, [:locale_id] => %i[set_debug_logging download] do |_task, args|
      unless args[:locale_id]
        Foxtail::CLDR.logger.error "Usage: rake cldr:extract:locale[locale_id]"
        Foxtail::CLDR.logger.error "Example: rake cldr:extract:locale[en]"
        exit 1
      end

      # Extract each data type for the specific locale
      extractors = [
        Foxtail::CLDR::Extractor::PluralRules.new(
          source_dir: CLDR_EXTRACT_DIR,
          output_dir: Foxtail.cldr_dir
        ),
        Foxtail::CLDR::Extractor::NumberFormats.new(
          source_dir: CLDR_EXTRACT_DIR,
          output_dir: Foxtail.cldr_dir
        ),
        Foxtail::CLDR::Extractor::Currencies.new(
          source_dir: CLDR_EXTRACT_DIR,
          output_dir: Foxtail.cldr_dir
        ),
        Foxtail::CLDR::Extractor::Units.new(
          source_dir: CLDR_EXTRACT_DIR,
          output_dir: Foxtail.cldr_dir
        ),
        Foxtail::CLDR::Extractor::DateTimeFormats.new(
          source_dir: CLDR_EXTRACT_DIR,
          output_dir: Foxtail.cldr_dir
        )
      ]

      extractors.each {|extractor| extractor.extract_locale(args[:locale_id]) }
    end

    desc "Extract CLDR plural rules from downloaded CLDR core data"
    task plural_rules: %i[set_debug_logging download parent_locales] do
      extractor = Foxtail::CLDR::Extractor::PluralRules.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end

    desc "Extract CLDR number formats from downloaded CLDR core data"
    task number_formats: %i[set_debug_logging download parent_locales] do
      extractor = Foxtail::CLDR::Extractor::NumberFormats.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end

    desc "Extract CLDR currencies from downloaded CLDR core data"
    task currencies: %i[set_debug_logging download parent_locales] do
      extractor = Foxtail::CLDR::Extractor::Currencies.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end

    desc "Extract CLDR units from downloaded CLDR core data"
    task units: %i[set_debug_logging download parent_locales] do
      extractor = Foxtail::CLDR::Extractor::Units.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end

    desc "Extract CLDR timezone names from downloaded CLDR core data"
    task timezone_names: %i[set_debug_logging download parent_locales] do
      extractor = Foxtail::CLDR::Extractor::TimezoneNames.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end

    desc "Extract CLDR datetime formats from downloaded CLDR core data"
    task datetime_formats: %i[set_debug_logging download parent_locales] do
      extractor = Foxtail::CLDR::Extractor::DateTimeFormats.new(
        source_dir: CLDR_EXTRACT_DIR,
        output_dir: Foxtail.cldr_dir
      )

      extractor.extract_all
    end
  end
end
