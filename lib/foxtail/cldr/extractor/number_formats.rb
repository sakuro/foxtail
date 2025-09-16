# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractor
      # Extracts number format data from CLDR XML and writes to YAML files
      class NumberFormats < Base
        private def extract_data_from_xml(xml_doc)
          formats = extract_format_patterns(xml_doc)

          data = {
            "number_formats" => {
              "symbols" => extract_symbols(xml_doc),
              "decimal_formats" => {"standard" => formats["decimal"]},
              "percent_formats" => {"standard" => formats["percent"]},
              "currency_formats" => extract_currency_formats(xml_doc, formats),
              "scientific_formats" => {"standard" => formats["scientific"]},
              "compact_formats" => extract_compact_formats(xml_doc)
            }
          }

          # Add currency_fractions at the root level to match previous structure
          currency_fractions = extract_currency_fractions
          data["currency_fractions"] = currency_fractions unless currency_fractions.empty?

          data
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

          # Runtime inheritance system handles missing symbols via locale inheritance chain
          # This preserves correct CLDR inheritance (e.g., de_DE inherits from de, not root)

          symbols
        end

        private def extract_format_patterns(xml_doc)
          formats = {}

          # Decimal formats - get the standard pattern (no type attribute)
          xpath = "ldml/numbers/decimalFormats[@numberSystem='latn']/decimalFormatLength[not(@type)]/decimalFormat/pattern[not(@type)]"
          decimal_element = xml_doc.elements[xpath]
          formats["decimal"] = decimal_element.text if decimal_element

          # Percent formats - get the standard pattern
          xpath = "ldml/numbers/percentFormats[@numberSystem='latn']/percentFormatLength[not(@type)]/percentFormat/pattern[not(@type)]"
          percent_element = xml_doc.elements[xpath]
          formats["percent"] = percent_element.text if percent_element

          # Scientific formats - get the standard pattern
          xpath = "ldml/numbers/scientificFormats[@numberSystem='latn']/scientificFormatLength[not(@type)]/scientificFormat/pattern[not(@type)]"
          scientific_element = xml_doc.elements[xpath]
          formats["scientific"] = scientific_element.text if scientific_element

          # Currency formats - get the standard pattern
          xpath = "ldml/numbers/currencyFormats[@numberSystem='latn']/currencyFormatLength[not(@type)]/currencyFormat/pattern[not(@type)]"
          currency_element = xml_doc.elements[xpath]
          formats["currency"] = currency_element.text if currency_element

          # Runtime inheritance system handles missing patterns via locale inheritance chain
          # This preserves correct CLDR inheritance

          formats
        end

        private def extract_currency_fractions
          # Currency fractions come from supplemental data, not individual locale files
          # We need to read from supplemental/supplementalData.xml
          supplemental_path = @source_dir + "common" + "supplemental" + "supplementalData.xml"

          return {} unless supplemental_path.exist?

          fractions = {}

          begin
            supplemental_doc = REXML::Document.new(supplemental_path.read)

            supplemental_doc.elements.each("supplementalData/currencyData/fractions/info") do |info|
              currency = info.attributes["iso4217"]
              next unless currency

              fraction_data = {}
              fraction_data["digits"] = Integer(info.attributes["digits"], 10) if info.attributes["digits"]
              fraction_data["rounding"] = Integer(info.attributes["rounding"], 10) if info.attributes["rounding"]
              fraction_data["cash_digits"] = Integer(info.attributes["cashDigits"], 10) if info.attributes["cashDigits"]
              if info.attributes["cashRounding"]
                fraction_data["cash_rounding"] =
                  Integer(info.attributes["cashRounding"], 10)
              end

              fractions[currency] = fraction_data unless fraction_data.empty?
            end
          rescue => e
            CLDR.logger.warn "Could not extract currency fractions: #{e.message}"
          end

          fractions
        end

        private def extract_currency_formats(xml_doc, formats)
          currency_formats = {"standard" => formats["currency"]}

          # Check for accounting pattern
          xpath = "ldml/numbers/currencyFormats[@numberSystem='latn']/currencyFormatLength[not(@type)]/currencyFormat[@type='accounting']"
          accounting_format = xml_doc.elements[xpath]

          if accounting_format
            # Check for direct pattern
            pattern_element = accounting_format.elements["pattern[not(@type)]"]
            if pattern_element
              currency_formats["accounting"] = pattern_element.text
            else
              # Check for alias
              alias_element = accounting_format.elements["alias"]
              if alias_element && alias_element.attributes["path"] == "../currencyFormat[@type='standard']" && formats["currency"]
                # Resolve alias: accounting -> standard
                currency_formats["accounting"] = formats["currency"]
              end
            end
          end

          currency_formats
        end

        private def extract_compact_formats(xml_doc)
          compact_formats = {}

          # Extract short compact formats (like "0K", "0万")
          short_formats = {}
          xml_doc.elements.each("ldml/numbers/decimalFormats[@numberSystem='latn']/decimalFormatLength[@type='short']/decimalFormat/pattern") do |pattern|
            type = pattern.attributes["type"]
            count = pattern.attributes["count"] || "other"
            next unless type && pattern.text

            short_formats[type] ||= {}
            short_formats[type][count] = pattern.text
          end
          compact_formats["short"] = short_formats unless short_formats.empty?

          # Extract long compact formats (like "0 thousand", "0万")
          long_formats = {}
          xml_doc.elements.each("ldml/numbers/decimalFormats[@numberSystem='latn']/decimalFormatLength[@type='long']/decimalFormat/pattern") do |pattern|
            type = pattern.attributes["type"]
            count = pattern.attributes["count"] || "other"
            next unless type && pattern.text

            long_formats[type] ||= {}
            long_formats[type][count] = pattern.text
          end
          compact_formats["long"] = long_formats unless long_formats.empty?

          compact_formats
        end
      end
    end
  end
end
