# frozen_string_literal: true

require_relative "base_extractor"

module Foxtail
  module CLDR
    module Extractors
      # Extracts number format data from CLDR XML and writes to YAML files
      class NumberFormatsExtractor < BaseExtractor
        private def data_type_name
          "number formats"
        end

        private def extract_data_from_xml(xml_doc)
          {
            "symbols" => extract_symbols(xml_doc),
            "formats" => extract_format_patterns(xml_doc),
            "currencies" => extract_currencies(xml_doc)
          }
        end

        private def data?(data)
          return false unless data.is_a?(Hash)

          data.any? {|_, section_data| section_data.is_a?(Hash) && !section_data.empty? }
        end

        private def write_data(locale_id, data)
          write_yaml_file(locale_id, "number_formats.yml", data)
        end

        private def extract_symbols(xml_doc)
          symbols = {}

          symbol_mappings = {
            "decimal" => "decimal",
            "group" => "group",
            "minusSign" => "minus_sign",
            "plusSign" => "plus_sign",
            "percentSign" => "percent_sign",
            "perMille" => "per_mille",
            "exponential" => "exponential",
            "infinity" => "infinity",
            "nan" => "nan"
          }

          symbol_mappings.each do |xpath_name, key_name|
            xml_doc.elements.each("ldml/numbers/symbols[@numberSystem='latn']/#{xpath_name}") do |element|
              symbols[key_name] = element.text
            end
          end

          symbols
        end

        private def extract_format_patterns(xml_doc)
          formats = {}

          # Decimal formats
          xpath = "ldml/numbers/decimalFormats[@numberSystem='latn']/decimalFormatLength/decimalFormat/pattern"
          xml_doc.elements.each(xpath) do |element|
            formats["decimal"] = element.text
          end

          # Percent formats
          xpath = "ldml/numbers/percentFormats[@numberSystem='latn']/percentFormatLength/percentFormat/pattern"
          xml_doc.elements.each(xpath) do |element|
            formats["percent"] = element.text
          end

          # Scientific formats
          xpath = "ldml/numbers/scientificFormats[@numberSystem='latn']/scientificFormatLength/scientificFormat/pattern"
          xml_doc.elements.each(xpath) do |element|
            formats["scientific"] = element.text
          end

          # Currency formats
          xpath = "ldml/numbers/currencyFormats[@numberSystem='latn']/currencyFormatLength/currencyFormat/pattern"
          xml_doc.elements.each(xpath) do |element|
            formats["currency"] = element.text
          end

          formats
        end

        private def extract_currencies(xml_doc)
          currencies = {}

          xml_doc.elements.each("ldml/numbers/currencies/currency") do |currency|
            code = currency.attributes["type"]
            next unless code

            currency_data = {}

            # Symbol
            currency.elements.each("symbol") do |symbol|
              currency_data["symbol"] = symbol.text
            end

            # Display name (singular)
            currency.elements.each("displayName") do |name|
              count = name.attributes["count"]
              if count
                currency_data["display_name_#{count}"] = name.text
              else
                currency_data["display_name"] = name.text
              end
            end

            currencies[code] = currency_data unless currency_data.empty?
          end

          currencies
        end
      end
    end
  end
end
