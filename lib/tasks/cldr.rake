# frozen_string_literal: true

require "fileutils"
require "rake/clean"
require "rexml/document"
require "shellwords"
require "time"
require "yaml"

# CLDR version configuration
CLDR_VERSION = "46"
CLDR_CORE_URL = "https://unicode.org/Public/cldr/#{CLDR_VERSION}/core.zip".freeze

# Define paths and file lists
PROJECT_ROOT = File.expand_path("../..", __dir__)
TMP_DIR = File.join(PROJECT_ROOT, "tmp")
DATA_DIR = File.join(PROJECT_ROOT, "data", "cldr")
CLDR_ZIP_PATH = File.join(TMP_DIR, "cldr-core.zip")
CLDR_EXTRACT_DIR = File.join(TMP_DIR, "cldr-core")

PLURAL_RULES_FILES = FileList[File.join(DATA_DIR, "*/plural_rules.yml")]
NUMBER_FORMATS_FILES = FileList[File.join(DATA_DIR, "*/number_formats.yml")]
DATETIME_FORMATS_FILES = FileList[File.join(DATA_DIR, "*/datetime_formats.yml")]

# CLDR source XML files
CLDR_LOCALE_XML_FILES = FileList[File.join(TMP_DIR, "cldr-core/common/main/*.xml")]

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

    # Extract with unzip using shelljoin
    unzip_cmd = ["unzip", "-q", File.basename(CLDR_ZIP_PATH), "-d", File.basename(CLDR_EXTRACT_DIR)]
    Dir.chdir(TMP_DIR) do
      sh Shellwords.join(unzip_cmd)
    end

    # Clean up zip file
    File.delete(CLDR_ZIP_PATH)
    puts "CLDR core data ready at #{CLDR_EXTRACT_DIR}"

    # Show some stats
    common_dir = File.join(CLDR_EXTRACT_DIR, "common")
    if Dir.exist?(common_dir)
      locales_dir = File.join(common_dir, "main")
      if Dir.exist?(locales_dir)
        locale_count = Dir.glob(File.join(locales_dir, "*.xml")).size
        puts "Found #{locale_count} locale files"
      end
    end
  end

  # New hierarchical extract namespace
  namespace :extract do
    desc "Extract all CLDR data (plural_rules, number_formats, datetime_formats)"
    task all: %i[plural_rules number_formats datetime_formats]

    desc "Extract CLDR plural rules from downloaded CLDR core data"
    task plural_rules: :download do
      plurals_xml_path = File.join(CLDR_EXTRACT_DIR, "common", "supplemental", "plurals.xml")

      unless File.exist?(plurals_xml_path)
        puts "CLDR plurals.xml not found. Run 'rake cldr:download' first."
        exit 1
      end

      # Clean up existing plural_rules files before regeneration
      if PLURAL_RULES_FILES.any?
        puts "Cleaning up #{PLURAL_RULES_FILES.size} existing plural_rules files..."
        rm PLURAL_RULES_FILES
      end

      puts "Processing CLDR plural rules from #{plurals_xml_path}..."

      require "rexml/document"

      # Parse plurals.xml
      doc = REXML::Document.new(File.read(plurals_xml_path))
      locale_rules = {}

      # Extract plural rules from cardinal plurals
      doc.elements.each("supplementalData/plurals[@type='cardinal']/pluralRules") do |plural_rules|
        locales = plural_rules.attributes["locales"].split(/\s+/)

        rules = {}
        plural_rules.elements.each("pluralRule") do |rule|
          count = rule.attributes["count"]
          condition = rule.text&.strip || ""

          # Remove @integer and @decimal sections
          condition = condition.split("@")[0].strip if condition.include?("@")

          rules[count] = condition
        end

        # Apply rules to all locales in this group
        locales.each do |locale|
          locale_rules[locale] = rules
        end
      end

      # Create data directory
      FileUtils.mkdir_p(DATA_DIR)

      puts "Processing #{locale_rules.keys.size} locales..."

      # Process each locale
      locale_rules.each do |locale, rules|
        # Create locale directory
        locale_dir = File.join(DATA_DIR, locale)
        FileUtils.mkdir_p(locale_dir)

        # Skip if no rules found
        next if rules.empty?

        # Rules are already cleaned during extraction
        # Write YAML file
        yaml_data = {
          "locale" => locale,
          "plural_rules" => rules,
          "generated_at" => Time.now.iso8601,
          "cldr_version" => "v#{CLDR_VERSION}",
          "source" => "Unicode CLDR"
        }

        yaml_path = File.join(locale_dir, "plural_rules.yml")
        File.write(yaml_path, yaml_data.to_yaml)
        puts "  Created: #{yaml_path}"
      end

      puts "CLDR plural rules extraction complete!"
    end

    desc "Extract CLDR datetime formats from downloaded CLDR core data"
    task datetime_formats: :download do
      locales_dir = File.join(CLDR_EXTRACT_DIR, "common", "main")

      unless Dir.exist?(locales_dir)
        puts "CLDR locales directory not found. Run 'rake cldr:download' first."
        exit 1
      end

      # Clean up existing datetime_formats files before regeneration
      if DATETIME_FORMATS_FILES.any?
        puts "Cleaning up #{DATETIME_FORMATS_FILES.size} existing datetime_formats files..."
        rm DATETIME_FORMATS_FILES
      end

      puts "Processing CLDR datetime formats from #{locales_dir}..."

      # Create data directory
      FileUtils.mkdir_p(DATA_DIR)

      # Get all locale XML files
      locale_files = CLDR_LOCALE_XML_FILES
      puts "Found #{locale_files.size} locale files"

      processed_count = 0
      locale_files.each do |xml_file|
        locale = File.basename(xml_file, ".xml")

        # Skip root locale and other special cases
        next if locale == "root" || locale.include?("_")

        begin
          puts "  Processing locale: #{locale}"

          doc = REXML::Document.new(File.read(xml_file))

          # Extract calendar data (gregorian calendar)
          calendar = doc.elements["ldml/dates/calendars/calendar[@type='gregorian']"]
          next unless calendar

          datetime_formats = {}

          # Extract month names
          months = {}
          calendar.elements.each("months/monthContext") do |month_context|
            context = month_context.attributes["type"] # format, stand-alone
            months[context] = {}

            month_context.elements.each("monthWidth") do |month_width|
              width = month_width.attributes["type"] # abbreviated, narrow, wide
              months[context][width] = {}

              month_width.elements.each("month") do |month|
                month_num = month.attributes["type"]
                months[context][width][month_num] = month.text
              end
            end
          end
          datetime_formats["months"] = months unless months.empty?

          # Extract day names
          days = {}
          calendar.elements.each("days/dayContext") do |day_context|
            context = day_context.attributes["type"] # format, stand-alone
            days[context] = {}

            day_context.elements.each("dayWidth") do |day_width|
              width = day_width.attributes["type"] # abbreviated, narrow, short, wide
              days[context][width] = {}

              day_width.elements.each("day") do |day|
                day_key = day.attributes["type"] # sun, mon, tue, etc.
                days[context][width][day_key] = day.text
              end
            end
          end
          datetime_formats["days"] = days unless days.empty?

          # Extract date format patterns
          date_formats = {}
          calendar.elements.each("dateFormats/dateFormatLength") do |date_format|
            style = date_format.attributes["type"] # full, long, medium, short
            pattern_elem = date_format.elements["dateFormat/pattern"]
            if pattern_elem&.text
              date_formats[style] = pattern_elem.text
            end
          end
          datetime_formats["date_formats"] = date_formats unless date_formats.empty?

          # Extract time format patterns
          time_formats = {}
          calendar.elements.each("timeFormats/timeFormatLength") do |time_format|
            style = time_format.attributes["type"] # full, long, medium, short
            pattern_elem = time_format.elements["timeFormat/pattern"]
            if pattern_elem&.text
              time_formats[style] = pattern_elem.text
            end
          end
          datetime_formats["time_formats"] = time_formats unless time_formats.empty?

          # Skip if no useful data found
          next if datetime_formats.empty?

          # Create locale directory
          locale_dir = File.join(DATA_DIR, locale)
          FileUtils.mkdir_p(locale_dir)

          # Build YAML structure
          yaml_data = {
            "datetime_formats" => datetime_formats,
            "locale" => locale,
            "generated_at" => Time.now.iso8601,
            "cldr_version" => "v#{CLDR_VERSION}",
            "source" => "Unicode CLDR"
          }

          # Write YAML file
          yaml_path = File.join(locale_dir, "datetime_formats.yml")
          File.write(yaml_path, yaml_data.to_yaml)
          puts "    Created: #{yaml_path}"
          processed_count += 1
        rescue => e
          puts "    Error processing #{locale}: #{e.message}"
          next
        end
      end

      puts "CLDR datetime formats extraction complete! Processed #{processed_count} locales."
    end

    desc "Extract CLDR number formats from downloaded CLDR core data"
    task number_formats: :download do
      locales_dir = File.join(CLDR_EXTRACT_DIR, "common", "main")

      unless Dir.exist?(locales_dir)
        puts "CLDR locales directory not found. Run 'rake cldr:download' first."
        exit 1
      end

      # Clean up existing number_formats files before regeneration
      if NUMBER_FORMATS_FILES.any?
        puts "Cleaning up #{NUMBER_FORMATS_FILES.size} existing number_formats files..."
        rm NUMBER_FORMATS_FILES
      end

      puts "Processing CLDR number formats from #{locales_dir}..."

      # Create data directory
      FileUtils.mkdir_p(DATA_DIR)

      # Extract currency fractions data (shared across all locales)
      currency_fractions = {}
      supplemental_data_path = File.join(CLDR_EXTRACT_DIR, "common", "supplemental", "supplementalData.xml")
      if File.exist?(supplemental_data_path)
        puts "  Processing currency fractions from supplementalData.xml..."
        supplemental_doc = REXML::Document.new(File.read(supplemental_data_path))
        supplemental_doc.elements.each("supplementalData/currencyData/fractions/info") do |info|
          currency_code = info.attributes["iso4217"]
          digits = info.attributes["digits"] ? Integer(info.attributes["digits"], 10) : 2
          currency_fractions[currency_code] = {
            "digits" => digits,
            "rounding" => info.attributes["rounding"] ? Integer(info.attributes["rounding"], 10) : 0
          }
          # Add cash-specific data if available
          if info.attributes["cashDigits"]
            currency_fractions[currency_code]["cash_digits"] = Integer(info.attributes["cashDigits"], 10)
          end
          if info.attributes["cashRounding"]
            currency_fractions[currency_code]["cash_rounding"] = Integer(info.attributes["cashRounding"], 10)
          end
        end
        puts "    Loaded #{currency_fractions.size} currency fraction rules"
      end

      # Step 1: Process root locale for base data
      root_data = {}
      root_xml_path = File.join(CLDR_EXTRACT_DIR, "common", "main", "root.xml")
      if File.exist?(root_xml_path)
        puts "  Processing root locale for base inheritance data..."
        root_data = extract_number_format_data(root_xml_path, "root")
        puts "    Extracted root data with #{root_data["currencies"]&.size || 0} currencies"
      end

      # Step 2: Get all locale XML files
      locale_files = CLDR_LOCALE_XML_FILES
      puts "Found #{locale_files.size} locale files"

      processed_count = 0
      locale_files.each do |xml_file|
        locale = File.basename(xml_file, ".xml")

        # Skip root locale and other special cases
        next if locale == "root" || locale.include?("_")

        begin
          puts "  Processing locale: #{locale}"

          # Extract number formatting data using helper method
          number_formats = extract_number_format_data(xml_file, locale)
          # Apply inheritance if needed (merge with root data)
          if locale != "root" && !root_data.empty?
            number_formats = merge_with_inheritance(root_data, number_formats)
          end

          # Skip if no useful data found
          next if number_formats.empty?

          # Create locale directory
          locale_dir = File.join(DATA_DIR, locale)
          FileUtils.mkdir_p(locale_dir)

          # Build YAML structure
          yaml_data = {
            "number_formats" => number_formats,
            "locale" => locale,
            "generated_at" => Time.now.iso8601,
            "cldr_version" => "v#{CLDR_VERSION}",
            "source" => "Unicode CLDR"
          }

          # Add currency fractions data (shared across all locales, but included for convenience)
          yaml_data["currency_fractions"] = currency_fractions unless currency_fractions.empty?

          # Write YAML file
          yaml_path = File.join(locale_dir, "number_formats.yml")
          File.write(yaml_path, yaml_data.to_yaml)
          puts "    Created: #{yaml_path}"
          processed_count += 1
        rescue => e
          puts "    Error processing #{locale}: #{e.message}"
          next
        end
      end

      puts "CLDR number formats extraction complete! Processed #{processed_count} locales."
    end
  end

  # Helper method to extract number format data from a locale XML file
  private def extract_number_format_data(xml_file_path, locale_name)
    doc = REXML::Document.new(File.read(xml_file_path))
    number_formats = {}

    # Extract decimal symbols
    symbols = {}
    doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/decimal") do |element|
      symbols["decimal"] = element.text
    end
    doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/group") do |element|
      symbols["group"] = element.text
    end
    doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/minusSign") do |element|
      symbols["minus_sign"] = element.text
    end
    doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/plusSign") do |element|
      symbols["plus_sign"] = element.text
    end
    doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/percentSign") do |element|
      symbols["percent_sign"] = element.text
    end
    doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/perMille") do |element|
      symbols["per_mille"] = element.text
    end
    doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/infinity") do |element|
      symbols["infinity"] = element.text
    end
    doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/nan") do |element|
      symbols["nan"] = element.text
    end
    number_formats["symbols"] = symbols unless symbols.empty?

    # Extract decimal format patterns
    decimal_formats = {}
    doc.elements.each("ldml/numbers/decimalFormats[@numberSystem='latn']/decimalFormatLength[not(@type)]/decimalFormat/pattern") do |pattern|
      decimal_formats["standard"] = pattern.text
    end
    number_formats["decimal_formats"] = decimal_formats unless decimal_formats.empty?

    # Extract percent format patterns
    percent_formats = {}
    doc.elements.each("ldml/numbers/percentFormats[@numberSystem='latn']/percentFormatLength/percentFormat/pattern") do |pattern|
      percent_formats["standard"] = pattern.text
    end
    number_formats["percent_formats"] = percent_formats unless percent_formats.empty?

    # Extract currency format patterns
    currency_formats = {}
    doc.elements.each("ldml/numbers/currencyFormats[@numberSystem='latn']/currencyFormatLength[not(@type)]/currencyFormat[@type='standard']/pattern[not(@alt)]") do |pattern|
      currency_formats["standard"] = pattern.text
    end
    doc.elements.each("ldml/numbers/currencyFormats[@numberSystem='latn']/currencyFormatLength[not(@type)]/currencyFormat[@type='accounting']/pattern[not(@alt)]") do |pattern|
      currency_formats["accounting"] = pattern.text
    end
    number_formats["currency_formats"] = currency_formats unless currency_formats.empty?

    # Extract scientific format patterns
    scientific_formats = {}
    doc.elements.each("ldml/numbers/scientificFormats[@numberSystem='latn']/scientificFormatLength/scientificFormat/pattern") do |pattern|
      scientific_formats["standard"] = pattern.text
    end
    number_formats["scientific_formats"] = scientific_formats unless scientific_formats.empty?

    # Extract currency symbols and names
    currencies = {}
    doc.elements.each("ldml/numbers/currencies/currency") do |currency|
      currency_code = currency.attributes["type"]
      next unless currency_code

      currency_data = {}

      # Get symbol
      symbol_elem = currency.elements["symbol"]
      if symbol_elem&.text
        currency_data["symbol"] = symbol_elem.text
      end

      # Get display name (plural forms)
      display_names = {}
      currency.elements.each("displayName") do |display_name|
        count = display_name.attributes["count"]
        if count
          display_names[count] = display_name.text
        else
          display_names["other"] = display_name.text # Default form
        end
      end
      currency_data["display_names"] = display_names unless display_names.empty?

      currencies[currency_code] = currency_data unless currency_data.empty?
    end
    number_formats["currencies"] = currencies unless currencies.empty?

    number_formats
  rescue => e
    puts "    Error extracting data from #{locale_name}: #{e.message}"
    {}
  end

  # Merge locale data with parent data (inheritance)
  # Child data takes precedence over parent data
  def merge_with_inheritance(parent_data, child_data)
    merged = parent_data.dup

    child_data.each do |key, value|
      merged[key] = if value.is_a?(Hash) && merged[key].is_a?(Hash)
                      # Recursively merge hash values
                      merge_with_inheritance(merged[key], value)
                    else
                      # Child value takes precedence
                      value
                    end
    end

    merged
  end
end
