# frozen_string_literal: true

require "rexml/document"
require "yaml"
require_relative "single_file"

module Foxtail
  module CLDR
    module Extractor
      # CLDR metazone mapping data extractor
      #
      # Extracts timezone to metazone mapping data from CLDR supplemental XML files.
      # This language-independent data maps timezone IDs to metazone IDs with temporal
      # validity periods, then writes a single structured YAML file for use by
      # timezone processing.
      #
      # @see https://unicode.org/reports/tr35/tr35-dates.html#Metazone_Names
      class MetazoneMapping < SingleFile
        # Extract metazone mapping data from CLDR
        private def extract_data
          timezone_to_metazone = extract_metazone_mapping
          metazone_to_timezones = create_reverse_mapping(timezone_to_metazone)
          {
            "timezone_to_metazone" => timezone_to_metazone,
            "metazone_to_timezones" => metazone_to_timezones
          }
        end

        # Override describe_data to provide specific description for metazone mapping
        private def describe_data(data)
          timezone_count = data["timezone_to_metazone"]&.size || 0
          metazone_count = data["metazone_to_timezones"]&.size || 0
          "#{timezone_count} timezones -> #{metazone_count} metazones"
        end

        private def extract_metazone_mapping
          metazones_file = @source_dir + "common" + "supplemental" + "metaZones.xml"

          doc = REXML::Document.new(metazones_file.read)
          mapping = {}

          # Extract timezone -> metazone mappings
          doc.elements.each("supplementalData/metaZones/metazoneInfo/timezone") do |timezone_element|
            timezone_id = timezone_element.attributes["type"]
            next unless timezone_id

            # Get the current metazone (most recent without 'to' attribute)
            current_metazone = nil
            timezone_element.elements.each("usesMetazone") do |uses_element|
              mzone = uses_element.attributes["mzone"]
              to_attr = uses_element.attributes["to"]

              # If no 'to' attribute, this is the current/active metazone
              if to_attr.nil?
                current_metazone = mzone
                break
              end
            end

            # Store the mapping if we found a current metazone
            mapping[timezone_id] = current_metazone if current_metazone
          end

          mapping
        end

        # Create reverse mapping: metazone -> [timezone_ids]
        private def create_reverse_mapping(timezone_to_metazone)
          timezone_to_metazone.group_by(&:last).transform_values {|pairs| pairs.map(&:first).sort! }
        end
      end
    end
  end
end
