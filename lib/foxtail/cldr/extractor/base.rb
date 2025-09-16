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
        end

        # Instance method to access the shared inflector
        # @return [Dry::Inflector] Inflector instance for string transformations
        private def inflector
          self.class.inflector
        end

        # Check if we should skip writing the file
        # @param file_path [String] Path to the file
        # @param new_data [Hash] Data to be written
        # @return [Boolean] true if write should be skipped
        private def should_skip_write?(file_path, new_data)
          return false unless file_path.exist?

          existing_data = YAML.load_file(file_path.to_s)
          return false unless existing_data.is_a?(Hash)

          # Compare data without generated_at
          new_data.except("generated_at") == existing_data.except("generated_at")
        rescue => e
          CLDR.logger.debug "Error comparing existing file: #{e.message}"
          false
        end

        # Automatically derive data filename from class name using inflector
        private def data_filename
          # Get the class name without module prefix (e.g., "LocaleAliases")
          class_name = inflector.demodulize(self.class)
          # Convert to snake_case and add .yml extension
          "#{inflector.underscore(class_name)}.yml"
        end
      end
    end
  end
end
