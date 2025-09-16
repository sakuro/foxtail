# frozen_string_literal: true

require "rexml/document"
require "yaml"
require_relative "single_file"

module Foxtail
  module CLDR
    module Extractor
      # CLDR parent locales data extractor
      #
      # Extracts parent locale mappings from CLDR supplemental data for locale
      # inheritance resolution, then writes a single structured YAML file for
      # use by the locale inheritance system.
      #
      # @see https://unicode.org/reports/tr35/tr35-core.html#Locale_Inheritance
      class ParentLocales < SingleFile
        # Extract parent locale mappings for all components
        # @return [Hash] Parent locale mappings
        private def extract_data
          parent_locales = extract_parent_locales
          {"parent_locales" => parent_locales}
        end

        private def extract_parent_locales
          supplemental_path = @source_dir + "common" + "supplemental" + "supplementalData.xml"

          parents = {}

          begin
            doc = REXML::Document.new(supplemental_path.read)

            # Extract parent locale relationships
            doc.elements.each("supplementalData/parentLocales/parentLocale") do |parent_element|
              parent = parent_element.attributes["parent"]
              locales_attr = parent_element.attributes["locales"]

              next unless parent && locales_attr

              # Parse locale list: "en_AU en_CA" -> ["en_AU", "en_CA"]
              locales = locales_attr.split(/\s+/)
              locales.each do |locale|
                parents[locale] = parent
              end
            end
          rescue => e
            CLDR.logger.warn "Could not load parent locales: #{e.message}"
          end

          parents
        end
      end
    end
  end
end
