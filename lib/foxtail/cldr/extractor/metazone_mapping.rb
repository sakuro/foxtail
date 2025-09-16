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
          output_file = @output_dir + "metazone_mapping.yml"

          yaml_data = {
            "generated_at" => Time.now.utc.iso8601,
            "cldr_version" => ENV.fetch("CLDR_VERSION", "46")
          }.merge(mapping_data)

          # Skip writing if only generated_at differs
          unless should_skip_write?(output_file, yaml_data)
            output_file.write(YAML.dump(yaml_data))
            Foxtail::CLDR.logger.debug "Wrote metazone mapping to #{relative_path(output_file)}"
          end

          timezone_count = mapping_data["timezone_to_metazone"]&.size || 0
          metazone_count = mapping_data["metazone_to_timezones"]&.size || 0
          Foxtail::CLDR.logger.info "Metazone mapping extracted (#{timezone_count} timezones -> #{metazone_count} metazones)"
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

          generate_mapping_data(mapping)
        end

        # Generate the final mapping data structure
        private def generate_mapping_data(timezone_to_metazone)
          {
            "timezone_to_metazone" => timezone_to_metazone,
            # Also create reverse mapping for convenience
            "metazone_to_timezones" => create_reverse_mapping(timezone_to_metazone)
          }
        end

        # Create reverse mapping: metazone -> [timezone_ids]
        private def create_reverse_mapping(timezone_to_metazone)
          reverse = Hash.new {|h, k| h[k] = [] }

          timezone_to_metazone.each do |timezone_id, metazone_id|
            reverse[metazone_id] << timezone_id
          end

          # Convert to regular hash and sort arrays
          reverse.transform_values(&:sort).to_h
        end
      end
    end
  end
end
