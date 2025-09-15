# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractor
      # Extracts unit data from CLDR XML and writes to YAML files
      class Units < Base
        private def extract_data_from_xml(xml_doc)
          units = extract_units(xml_doc)

          {
            "units" => units
          }
        end

        private def data?(data)
          return false unless data.is_a?(Hash)
          return false unless data["units"].is_a?(Hash)

          !data["units"].empty?
        end

        private def write_data(locale_id, data)
          write_yaml_file(locale_id, "units.yml", data)
        end

        # Extract unit formatting data from CLDR XML
        private def extract_units(xml_doc)
          units = {}

          # Extract from units/unitLength sections (long and short forms)
          %w[long short narrow].each do |unit_width|
            xpath = "//units/unitLength[@type='#{unit_width}']/unit"
            xml_doc.elements.each(xpath) do |unit_element|
              unit_type = unit_element.attributes["type"]
              next unless unit_type

              # Parse unit type (e.g., "length-kilometer" -> category: "length", unit: "kilometer")
              parts = unit_type.split("-", 2)
              next unless parts.length == 2

              category = parts[0]
              unit_name = parts[1]

              units[unit_name] ||= {}
              units[unit_name][unit_width] ||= {}

              # Extract display name
              display_name_element = unit_element.elements["displayName"]
              if display_name_element
                units[unit_name][unit_width]["display_name"] = display_name_element.text
              end

              # Extract unit patterns for different plural forms
              unit_element.elements.each("unitPattern") do |pattern_element|
                count = pattern_element.attributes["count"] || "other"
                case_attr = pattern_element.attributes["case"]

                pattern_key = case_attr ? "#{count}_#{case_attr}" : count
                units[unit_name][unit_width][pattern_key] = pattern_element.text
              end

              # Extract gender information (for German, etc.)
              gender_element = unit_element.elements["gender"]
              if gender_element
                units[unit_name][unit_width]["gender"] = gender_element.text
              end

              # Extract per-unit pattern
              per_unit_element = unit_element.elements["perUnitPattern"]
              if per_unit_element
                units[unit_name][unit_width]["per_unit_pattern"] = per_unit_element.text
              end

              # Store category information
              units[unit_name]["category"] = category
            end
          end

          units
        end
      end
    end
  end
end