# frozen_string_literal: true

require "fileutils"
require "rexml/document"
require "time"
require "yaml"

module Foxtail
  module CLDR
    module Extractor
      # Base class for CLDR data extractors providing common functionality
      class Base
        attr_reader :source_dir
        attr_reader :output_dir

        def initialize(source_dir:, output_dir:)
          @source_dir = source_dir
          @output_dir = output_dir
          @parent_locales = nil
          @inheritance = Repository::Inheritance.instance
          @extracted_data_cache = {}
        end

        # Template method for extracting all locales
        def extract_all
          validate_source_directory

          locale_files = Dir.glob(File.join(source_dir, "common", "main", "*.xml"))
          CLDR.logger.info "Extracting #{data_type_name} from #{locale_files.size} locales..."

          locale_files.each do |xml_file|
            locale_id = File.basename(xml_file, ".xml")
            extract_locale(locale_id)
          end

          CLDR.logger.info "#{data_type_name.capitalize} extraction complete (#{locale_files.size} locales)"
        end

        # Template method for extracting a specific locale
        def extract_locale(locale_id)
          extracted_data = extract_locale_with_inheritance(locale_id)

          # Only write if we have meaningful data
          return unless extracted_data && data?(extracted_data)

          write_data(locale_id, extracted_data)
        end

        # Extract minimal locale data (only differences from parent)
        def extract_locale_with_inheritance(locale_id)
          return @extracted_data_cache[locale_id] if @extracted_data_cache.key?(locale_id)

          load_parent_locales_if_needed

          # Get raw data for this locale
          raw_data = load_raw_locale_data(locale_id)
          return nil unless raw_data

          # Get parent data to compare against
          parent_locale = get_parent_locale(locale_id)
          unless parent_locale
            @extracted_data_cache[locale_id] = raw_data
            return raw_data
          end

          parent_data = extract_locale_with_inheritance(parent_locale)
          unless parent_data
            @extracted_data_cache[locale_id] = raw_data
            return raw_data
          end

          # Extract only the differences
          result = extract_differences(raw_data, parent_data)
          @extracted_data_cache[locale_id] = result
          result
        end

        private def validate_source_directory
          locales_dir = File.join(source_dir, "common", "main")

          return if Dir.exist?(locales_dir)

          raise ArgumentError, "CLDR source directory not found: #{locales_dir}"
        end

        private def load_parent_locales_if_needed
          return if @parent_locales

          @parent_locales = @inheritance.load_parent_locales(source_dir)
          CLDR.logger.debug "Loaded #{@parent_locales.size} parent locale mappings" unless @parent_locales.empty?
        end

        private def parent_locales
          @parent_locales ||= {}
        end

        private def load_raw_locale_data(locale_id)
          xml_path = File.join(source_dir, "common", "main", "#{locale_id}.xml")
          return nil unless File.exist?(xml_path)

          begin
            doc = REXML::Document.new(File.read(xml_path))
            extract_data_from_xml(doc)
          rescue => e
            CLDR.logger.warn "Could not load data for locale #{locale_id}: #{e.message}"
            nil
          end
        end

        private def get_parent_locale(locale_id)
          return nil if locale_id == "root"

          # Check explicit parent mappings first
          if parent_locales[locale_id]
            parent_locales[locale_id]
          else
            # Use algorithmic parent resolution
            chain = @inheritance.resolve_inheritance_chain(locale_id)
            chain[1] if chain.length > 1
          end
        end

        private def extract_differences(child_data, parent_data)
          return child_data unless child_data.is_a?(Hash) && parent_data.is_a?(Hash)

          diff = {}

          child_data.each do |key, value|
            parent_value = parent_data[key]

            if value != parent_value
              if value.is_a?(Hash) && parent_value.is_a?(Hash)
                # Recursively extract differences for nested hashes
                nested_diff = extract_differences(value, parent_value)
                diff[key] = nested_diff unless nested_diff.empty?
              else
                diff[key] = value
              end
            end
          end

          diff
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
      end
    end
  end
end
