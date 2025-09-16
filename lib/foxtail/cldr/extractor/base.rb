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

        # Convert absolute path to relative path from data output directory
        private def relative_path(file_path)
          file_path.relative_path_from(@output_dir)
        rescue ArgumentError
          # Fallback to absolute path if relative path calculation fails
          file_path
        end
      end
    end
  end
end
