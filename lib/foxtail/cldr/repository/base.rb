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

        def initialize(locale)
          @locale = locale
          @resolver = Resolver.new(@locale)

          # Check data availability during construction
          return if data?

          raise DataNotAvailable, "CLDR data not available for locale: #{@locale}"
        end

        # Instance method to access the shared inflector
        def inflector
          self.class.inflector
        end

        private def data?
          !find_available_data_file.nil?
        end

        # Find the first available data file in the fallback chain
        private def find_available_data_file
          locale_candidates.each do |candidate|
            path = data_file_path(candidate)
            return path if path.exist?
          end
          nil
        end

        # Get locale candidates using Locale library's fallback chain
        private def locale_candidates
          return [] unless @locale

          candidates = @locale.to_simple.candidates.map(&:to_s)
          candidates.reject!(&:empty?)
          candidates
        end

        # Construct data file path for a given locale candidate
        private def data_file_path(locale_str)
          Foxtail.cldr_dir + locale_str + data_filename
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
