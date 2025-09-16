# frozen_string_literal: true

require_relative "multi_locale"

module Foxtail
  module CLDR
    module Extractor
      # CLDR timezone names data extractor
      #
      # Extracts locale-specific timezone name information from CLDR XML files
      # including display names, abbreviations, exemplar cities, and metazone names,
      # then writes structured YAML files for use by the timezone names repository.
      #
      # @see https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Names
      class TimezoneNames < MultiLocale
        private def extract_data_from_xml(xml_doc)
          {"timezone_names" => extract_timezone_names(xml_doc)}
        end

        private def data?(data)
          return false unless data.is_a?(Hash)
          return false unless data["timezone_names"].is_a?(Hash)

          !data["timezone_names"].empty?
        end

        private def extract_timezone_names(xml_doc)
          timezone_data = {}

          # Extract timezone format patterns
          timezone_names_elem = xml_doc.elements["ldml/dates/timeZoneNames"]
          return timezone_data unless timezone_names_elem

          # Format patterns (hourFormat, gmtFormat, etc.)
          formats = extract_timezone_formats(timezone_names_elem)
          timezone_data["formats"] = formats unless formats.empty?

          # Zone-specific names
          zones = extract_zone_names(timezone_names_elem)
          timezone_data["zones"] = zones unless zones.empty?

          # Metazone names (generic timezone names like "Pacific Time")
          metazones = extract_metazone_names(timezone_names_elem)
          timezone_data["metazones"] = metazones unless metazones.empty?

          timezone_data
        end

        private def extract_timezone_formats(timezone_names_elem)
          formats = {}

          # Hour format pattern (+HH:mm;-HH:mm)
          hour_format = timezone_names_elem.elements["hourFormat"]&.text
          formats["hour_format"] = hour_format if hour_format

          # GMT format pattern (GMT{0})
          gmt_format = timezone_names_elem.elements["gmtFormat"]&.text
          formats["gmt_format"] = gmt_format if gmt_format

          # Region format patterns
          timezone_names_elem.elements.each("regionFormat") do |region_format|
            type = region_format.attributes["type"]
            key = type ? "region_format_#{type}" : "region_format"
            formats[key] = region_format.text if region_format.text
          end

          # Fallback format
          fallback_format = timezone_names_elem.elements["fallbackFormat"]&.text
          formats["fallback_format"] = fallback_format if fallback_format

          formats
        end

        private def extract_zone_names(timezone_names_elem)
          zones = {}

          timezone_names_elem.elements.each("zone") do |zone|
            zone_id = zone.attributes["type"]
            next unless zone_id

            zone_data = {}

            # Exemplar city name
            exemplar_city = zone.elements["exemplarCity"]&.text
            zone_data["exemplar_city"] = exemplar_city if exemplar_city

            # Short names (abbreviations like "PST", "PDT")
            short_names = extract_timezone_name_variants(zone, "short")
            zone_data["short"] = short_names unless short_names.empty?

            # Long names (full names like "Pacific Standard Time")
            long_names = extract_timezone_name_variants(zone, "long")
            zone_data["long"] = long_names unless long_names.empty?

            zones[zone_id] = zone_data unless zone_data.empty?
          end

          zones
        end

        private def extract_metazone_names(timezone_names_elem)
          metazones = {}

          timezone_names_elem.elements.each("metazone") do |metazone|
            metazone_id = metazone.attributes["type"]
            next unless metazone_id

            metazone_data = {}

            # Short names for metazone
            short_names = extract_timezone_name_variants(metazone, "short")
            metazone_data["short"] = short_names unless short_names.empty?

            # Long names for metazone
            long_names = extract_timezone_name_variants(metazone, "long")
            metazone_data["long"] = long_names unless long_names.empty?

            metazones[metazone_id] = metazone_data unless metazone_data.empty?
          end

          metazones
        end

        private def extract_timezone_name_variants(parent_element, length_type)
          variants = {}

          length_elem = parent_element.elements[length_type]
          return variants unless length_elem

          # Extract different time variants (generic, standard, daylight)
          %w[generic standard daylight].each do |variant|
            variant_elem = length_elem.elements[variant]
            next unless variant_elem&.text

            variants[variant] = variant_elem.text
          end

          variants
        end
      end
    end
  end
end
