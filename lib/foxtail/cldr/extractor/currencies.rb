# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractor
      # CLDR currency data extractor
      #
      # Extracts locale-specific currency information from CLDR XML files including
      # display names, symbols, and formatting data, then writes structured YAML
      # files for use by the currency repository.
      #
      # @see https://unicode.org/reports/tr35/tr35-numbers.html#Currencies
      class Currencies < Base
        private def extract_data_from_xml(xml_doc)
          currencies = extract_currencies(xml_doc)

          {
            "currencies" => currencies
          }
        end

        private def data?(data)
          return false unless data.is_a?(Hash)
          return false unless data["currencies"].is_a?(Hash)

          !data["currencies"].empty?
        end

        private def write_data(locale_id, data)
          write_yaml_file(locale_id, "currencies.yml", data)
        end

        private def extract_currencies(xml_doc)
          currencies = {}

          xml_doc.elements.each("ldml/numbers/currencies/currency") do |currency|
            code = currency.attributes["type"]
            next unless code

            currency_data = {}

            # Symbol (prefer non-narrow, same logic as NumberFormats)
            symbol_element = currency.elements["symbol[not(@alt)]"] || currency.elements["symbol"]
            if symbol_element
              currency_data["symbol"] = symbol_element.text
            end

            # Display names with nested structure
            display_names = extract_display_names(currency)
            currency_data["display_names"] = display_names unless display_names.empty?

            currencies[code] = currency_data unless currency_data.empty?
          end

          currencies
        end

        private def extract_display_names(currency)
          display_names = {}

          currency.elements.each("displayName") do |name|
            count = name.attributes["count"]
            if count
              display_names[count] = name.text
            else
              # Default to "other" for consistency
              display_names["other"] = name.text
              # Also set specific forms if no count attribute
              display_names["one"] = name.text unless display_names.key?("one")
            end
          end

          display_names
        end
      end
    end
  end
end
