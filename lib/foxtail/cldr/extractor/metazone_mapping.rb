# frozen_string_literal: true

require "rexml/document"
require "yaml"

module Foxtail
  module CLDR
    module Extractor
      # Extracts timezone to metazone mapping data from CLDR XML files
      # This data is language-independent and maps timezone IDs to metazone IDs
      class MetazoneMapping < Base
        # Extract metazone mapping data from CLDR
        def extract_all
          Foxtail::CLDR.logger.info "Extracting metazone mapping data..."

          mapping_data = extract_metazone_mapping
          output_file = File.join(@output_dir, "metazone_mapping.yml")

          File.write(output_file, YAML.dump(mapping_data))
          Foxtail::CLDR.logger.info "Metazone mapping extracted to #{output_file}"
        end

        private

        # Extract metazone mapping from metaZones.xml
        def extract_metazone_mapping
          metazones_file = File.join(@source_dir, "common", "supplemental", "metaZones.xml")

          unless File.exist?(metazones_file)
            Foxtail::CLDR.logger.warn "metaZones.xml not found at #{metazones_file}"
            return generate_empty_mapping
          end

          Foxtail::CLDR.logger.debug "Processing #{metazones_file}"

          doc = REXML::Document.new(File.read(metazones_file))
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

          generate_mapping_data(mapping)
        end

        # Generate the final mapping data structure
        def generate_mapping_data(timezone_to_metazone)
          {
            generated_at: Time.now.utc.iso8601,
            cldr_version: ENV.fetch("CLDR_VERSION", "46"),
            timezone_to_metazone: timezone_to_metazone,
            # Also create reverse mapping for convenience
            metazone_to_timezones: create_reverse_mapping(timezone_to_metazone)
          }
        end

        # Create reverse mapping: metazone -> [timezone_ids]
        def create_reverse_mapping(timezone_to_metazone)
          reverse = Hash.new { |h, k| h[k] = [] }

          timezone_to_metazone.each do |timezone_id, metazone_id|
            reverse[metazone_id] << timezone_id
          end

          # Convert to regular hash and sort arrays
          reverse.transform_values(&:sort).to_h
        end

        # Generate empty mapping data for fallback
        def generate_empty_mapping
          {
            generated_at: Time.now.utc.iso8601,
            cldr_version: ENV.fetch("CLDR_VERSION", "46"),
            timezone_to_metazone: {},
            metazone_to_timezones: {}
          }
        end
      end
    end
  end
end