# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractor
      # CLDR numbering systems data extractor
      #
      # Extracts global numbering system definitions from CLDR supplemental data,
      # including numeric digit mappings and algorithmic rule references.
      # This extractor focuses solely on the reference data for numbering systems,
      # while locale-specific settings are handled by NumberFormats extractor.
      #
      # @see https://unicode.org/reports/tr35/tr35-numbers.html#Numbering_Systems
      class NumberingSystems < SingleFile
        private def extract_data
          {
            "numbering_systems" => extract_numbering_systems
          }
        end

        private def extract_numbering_systems
          systems = {}

          # Path to numberingSystems.xml in supplemental data
          numbering_systems_path = @source_dir + "common" + "supplemental" + "numberingSystems.xml"

          return systems unless numbering_systems_path.exist?

          begin
            doc = REXML::Document.new(numbering_systems_path.read)

            doc.elements.each("supplementalData/numberingSystems/numberingSystem") do |element|
              id = element.attributes["id"]
              type = element.attributes["type"]

              system_data = {"type" => type}

              case type
              when "numeric"
                # Extract digit characters for positional systems
                digits = element.attributes["digits"]
                system_data["digits"] = digits if digits
              when "algorithmic"
                # Extract rule reference for algorithmic systems
                rules = element.attributes["rules"]
                system_data["rules"] = rules if rules
              end

              systems[id] = system_data
            end
          rescue => e
            Foxtail::CLDR.logger.error("Error extracting numbering systems: #{e.message}")
          end

          Foxtail::CLDR.logger.info("Extracted #{systems.size} numbering systems")
          systems
        end
      end
    end
  end
end
