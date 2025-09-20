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
          raise ArgumentError, "locale cannot be nil" unless locale

          @locale = locale
          raise DataNotAvailable, "CLDR data not available for locale: #{@locale}" unless data_available?

          @resolver = Resolver.new(@locale)
        end

        # Instance method to access the shared inflector
        def inflector
          self.class.inflector
        end

        # Check if data is available for the locale
        private def data_available?
          filename = "#{inflector.underscore(inflector.demodulize(self.class.name))}.yml"
          @locale.to_simple.candidates.any? do |candidate|
            (Foxtail.cldr_dir + candidate.to_s + filename).exist?
          end
        end
      end
    end
  end
end
