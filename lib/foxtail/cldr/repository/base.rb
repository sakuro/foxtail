# frozen_string_literal: true

require "dry/inflector"
require "yaml"

module Foxtail
  module CLDR
    module Repository
      # Base class for CLDR data access with common functionality
      class Base
        attr_reader :locale

        # Class method to access the shared inflector (lazy initialization)
        def self.inflector
          @inflector ||= Dry::Inflector.new do |inflections|
            # Register DateTime as an acronym so DateTimeFormats becomes datetime_formats
            inflections.acronym("DateTime")
          end
        end

        # Get the root CLDR data directory path
        def self.data_dir
          File.expand_path("../../../../data/cldr", __dir__)
        end

        def initialize(locale)
          @locale = locale
        end

        # Instance method to access the shared inflector
        def inflector
          self.class.inflector
        end

        private def data?
          !find_available_data_file.nil?
        end

        # Get locale candidates using Locale library's fallback chain
        private def locale_candidates
          return [] unless @locale

          candidates = @locale.to_simple.candidates.map(&:to_s)
          candidates.reject!(&:empty?)
          candidates
        end

        # Find the first available data file in the fallback chain
        private def find_available_data_file
          locale_candidates.each do |candidate|
            path = data_file_path(candidate)
            return path if File.exist?(path)
          end
          nil
        end

        # Construct data file path for a given locale candidate
        private def data_file_path(locale_str)
          File.join(self.class.data_dir, locale_str, data_filename)
        end

        # Load CLDR data with fallback support
        private def load_data
          data_path = find_available_data_file
          return {} unless data_path

          YAML.load_file(data_path) || {}
        end

        # Automatically derive data filename from class name using inflector
        private def data_filename
          # Get the class name without module prefix (e.g., "DateTimeFormats")
          class_name = self.class.name.split("::").last
          # Convert to snake_case and add .yml extension
          "#{inflector.underscore(class_name)}.yml"
        end
      end
    end
  end
end
