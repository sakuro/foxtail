# frozen_string_literal: true

require_relative "base_extractor"

module Foxtail
  module CLDR
    module Extractors
      # Extracts plural rules from CLDR XML data and writes to YAML files
      class PluralRulesExtractor < BaseExtractor
        private def data_type_name
          "plural rules"
        end

        private def extract_data_from_xml(xml_doc)
          plural_rules = {}

          xml_doc.elements.each("ldml/plurals/pluralRules/pluralRule") do |rule|
            count = rule.attributes["count"]
            plural_rules[count] = rule.text.strip if count && rule.text
          end

          plural_rules
        end

        private def data?(data)
          data.is_a?(Hash) && !data.empty?
        end

        private def write_data(locale_id, data)
          write_yaml_file(locale_id, "plural_rules.yml", data)
        end
      end
    end
  end
end
