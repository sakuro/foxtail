# frozen_string_literal: true

require "dry/inflector"
require "pathname"
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

        # Shared cache across all extractor instances
        # @return [Hash] Cache for extracted data shared between instances
        def self.extracted_data_cache
          @extracted_data_cache ||= {}
        end

        # Class method to access the shared inflector (lazy initialization)
        # @return [Dry::Inflector] Inflector instance for string transformations
        def self.inflector
          @inflector ||= Dry::Inflector.new do |inflections|
            # Register DateTime as an acronym so DateTimeFormats becomes datetime_formats
            inflections.acronym("DateTime")
          end
        end

        def initialize(source_dir:, output_dir:)
          @source_dir = source_dir
          @output_dir = output_dir
          @parent_locales = nil
          @inheritance = Repository::Inheritance.instance
          @processed_files = []
        end

        # Instance method to access the shared inflector
        # @return [Dry::Inflector] Inflector instance for string transformations
        def inflector
          self.class.inflector
        end

        # Access shared cache instance
        # @return [Hash] Cache for extracted data shared between instances
        def extracted_data_cache
          self.class.extracted_data_cache
        end

        # Template method for extracting all locales
        def extract_all
          validate_source_directory

          locale_files = @source_dir.glob("common/main/*.xml")
          CLDR.logger.info "Extracting #{self.class.name.split("::").last} from #{locale_files.size} locales..."

          locale_files.each_with_index do |xml_file, index|
            locale_id = xml_file.basename(".xml").to_s
            extract_locale(locale_id)

            # Progress indicator every 100 locales
            if (index + 1) % 100 == 0
              CLDR.logger.info "Progress: #{index + 1}/#{locale_files.size} locales processed"
            end
          end

          # Clean up obsolete files after processing all locales
          cleanup_obsolete_files

          CLDR.logger.info "#{self.class.name.split("::").last} extraction complete (#{locale_files.size} locales)"
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
          # Use underscore class name for cache key
          class_name = self.class.name ? self.class.name.split("::").last : "data"
          cache_key = "#{inflector.underscore(class_name)}:#{locale_id}"

          return extracted_data_cache[cache_key] if extracted_data_cache.key?(cache_key)

          # Get raw data for this locale
          raw_data = load_raw_locale_data(locale_id)
          unless raw_data
            extracted_data_cache[cache_key] = nil
            return nil
          end

          # Get parent data to compare against
          parent_locale_id = parent_locale(locale_id)
          unless parent_locale_id
            extracted_data_cache[cache_key] = raw_data
            return raw_data
          end

          parent_data = extract_locale_with_inheritance(parent_locale_id)
          unless parent_data
            extracted_data_cache[cache_key] = raw_data
            return raw_data
          end

          # Extract only the differences
          result = extract_differences(raw_data, parent_data)
          extracted_data_cache[cache_key] = result
          result
        end

        private def validate_source_directory
          locales_dir = @source_dir + "common" + "main"

          return if locales_dir.exist?

          raise ArgumentError, "CLDR source directory not found: #{locales_dir}"
        end

        private def parent_locale_ids
          @parent_locale_ids ||= @inheritance.load_parent_locale_ids(@output_dir)
        end

        private def load_raw_locale_data(locale_id)
          xml_path = @source_dir + "common" + "main" + "#{locale_id}.xml"
          return nil unless xml_path.exist?

          begin
            doc = REXML::Document.new(xml_path.read)
            extract_data_from_xml(doc)
          rescue => e
            CLDR.logger.warn "Could not load data for locale #{locale_id}: #{e.message}"
            nil
          end
        end

        private def parent_locale(locale_id)
          return nil if locale_id == "root"

          # Check explicit parent mappings first
          if parent_locale_ids[locale_id]
            parent_locale_ids[locale_id]
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
          locale_dir = @output_dir + locale_id
          locale_dir.mkpath
        end

        private def write_yaml_file(locale_id, filename, data)
          ensure_locale_directory(locale_id)

          file_path = @output_dir + locale_id + filename
          @processed_files << file_path

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

          # Skip writing if only generated_at differs
          if should_skip_write?(file_path, yaml_data)
            return
          end

          CLDR.logger.debug "Writing #{relative_path(file_path)}"
          file_path.write(yaml_data.to_yaml)
        end

        # Check if we should skip writing the file
        # @param file_path [String] Path to the file
        # @param new_data [Hash] Data to be written
        # @return [Boolean] true if write should be skipped
        private def should_skip_write?(file_path, new_data)
          return false unless file_path.exist?

          begin
            existing_data = YAML.load_file(file_path.to_s)
            return false unless existing_data.is_a?(Hash)

            # Compare data without generated_at
            new_data.except("generated_at") == existing_data.except("generated_at")
          rescue => e
            CLDR.logger.debug "Error comparing existing file: #{e.message}"
            false
          end
        end

        # Clean up files that are no longer needed (not processed in this run)
        private def cleanup_obsolete_files
          filename = data_filename
          existing_files = @output_dir.glob("*/#{filename}")
          obsolete_files = existing_files - @processed_files

          if obsolete_files.any?
            CLDR.logger.info "Removing #{obsolete_files.size} obsolete #{self.class.name.split("::").last} files..."
            obsolete_files.each do |file_path|
              CLDR.logger.debug "Removing obsolete file: #{relative_path(file_path)}"
              file_path.delete
            end
          else
            CLDR.logger.debug "No obsolete #{self.class.name.split("::").last} files to remove"
          end
        end

        # Automatically derive data filename from class name using inflector
        private def data_filename
          # Get the class name without module prefix (e.g., "DateTimeFormats")
          # Handle anonymous classes (for testing)
          class_name = self.class.name ? self.class.name.split("::").last : "data"
          # Convert to snake_case and add .yml extension
          "#{inflector.underscore(class_name)}.yml"
        end

        # Convert absolute path to relative path from data output directory
        private def relative_path(file_path)
          file_path.relative_path_from(@output_dir)
        rescue ArgumentError
          # Fallback to absolute path if relative path calculation fails
          file_path
        end

        # Abstract methods - subclasses must implement these

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
