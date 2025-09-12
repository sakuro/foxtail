# frozen_string_literal: true

require "fileutils"
require "rexml/document"
require "time"
require "yaml"
require_relative "../inheritance"

module Foxtail
  module CLDR
    module Extractors
      # Base class for CLDR data extractors providing common functionality
      class BaseExtractor
        attr_reader :source_dir
        attr_reader :output_dir

        def initialize(source_dir:, output_dir:)
          @source_dir = source_dir
          @output_dir = output_dir
          @parent_locales = nil
          @inheritance = Inheritance.instance
        end

        # Template method for extracting all locales
        def extract_all
          validate_source_directory

          locale_files = Dir.glob(File.join(source_dir, "common", "main", "*.xml"))
          log "Extracting #{data_type_name} from #{locale_files.size} locales..."

          locale_files.each do |xml_file|
            locale_id = File.basename(xml_file, ".xml")
            extract_locale(locale_id)
          end

          log "#{data_type_name} extraction complete"
        end

        # Template method for extracting a specific locale
        def extract_locale(locale_id)
          extracted_data = extract_locale_with_inheritance(locale_id)

          # Only write if we have meaningful data
          return unless extracted_data && data?(extracted_data)

          write_data(locale_id, extracted_data)
        end

        # Extract locale data with full CLDR inheritance chain
        def extract_locale_with_inheritance(locale_id)
          load_parent_locales_if_needed
          @inheritance.load_inherited_data(locale_id, source_dir, self, parent_locales)
        end

        private def validate_source_directory
          locales_dir = File.join(source_dir, "common", "main")

          return if Dir.exist?(locales_dir)

          raise ArgumentError, "CLDR source directory not found: #{locales_dir}"
        end

        private def load_parent_locales_if_needed
          return if @parent_locales

          @parent_locales = @inheritance.load_parent_locales(source_dir)
          log "Loaded #{@parent_locales.size} parent locale mappings" unless @parent_locales.empty?
        end

        private def parent_locales
          @parent_locales ||= {}
        end

        private def ensure_locale_directory(locale_id)
          locale_dir = File.join(output_dir, locale_id)
          FileUtils.mkdir_p(locale_dir)
        end

        private def write_yaml_file(locale_id, filename, data)
          ensure_locale_directory(locale_id)

          file_path = File.join(output_dir, locale_id, filename)

          yaml_data = {
            "locale" => locale_id,
            "generated_at" => Time.now.utc.iso8601,
            "cldr_version" => ENV.fetch("CLDR_VERSION", "46")
          }

          # Merge in the data, preserving its structure
          if data.is_a?(Hash)
            yaml_data.merge!(data)
          else
            yaml_data["data"] = data
          end

          File.write(file_path, yaml_data.to_yaml)
        end

        # Abstract methods - subclasses must implement these

        # @return [String] Human-readable name of the data type (e.g., "plural rules")
        private def data_type_name
          raise NotImplementedError, "Subclasses must implement data_type_name"
        end

        # Extract data from parsed XML document
        # @param xml_doc [REXML::Document] The parsed XML document
        # @return [Object] Extracted data in appropriate format
        private def extract_data_from_xml(xml_doc)
          raise NotImplementedError, "Subclasses must implement extract_data_from_xml"
        end

        # Check if extracted data contains meaningful content
        # @param data [Object] The extracted data
        # @return [Boolean] true if data should be written to file
        private def data?(data)
          raise NotImplementedError, "Subclasses must implement data?"
        end

        # Write extracted data to appropriate file(s)
        # @param locale_id [String] The locale identifier
        # @param data [Object] The extracted data
        private def write_data(locale_id, data)
          raise NotImplementedError, "Subclasses must implement write_data"
        end

        # Progress logging method for testing support
        private def log(message)
          puts message
        end
      end
    end
  end
end
