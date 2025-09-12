# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractors
      # Extracts number format data from CLDR XML and writes to YAML files
      class NumberFormatsExtractor < BaseExtractor
        private def data_type_name
          "number formats"
        end

        private def extract_data_from_xml(xml_doc)
          formats = extract_format_patterns(xml_doc)

          data = {
            "number_formats" => {
              "symbols" => extract_symbols(xml_doc),
              "decimal_formats" => {"standard" => formats["decimal"]},
              "percent_formats" => {"standard" => formats["percent"]},
              "currency_formats" => extract_currency_formats(xml_doc, formats),
              "scientific_formats" => {"standard" => formats["scientific"]},
              "currencies" => merge_locale_and_root_currencies(xml_doc)
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

          # Apply fallback symbols from root locale for missing symbols
          apply_fallback_symbols(symbols)

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

          # Apply fallback patterns from root locale for missing standard patterns
          apply_fallback_patterns(formats)

          formats
        end

        private def apply_fallback_patterns(formats)
          # Default patterns from root locale when not specified
          fallback_patterns = {
            "decimal" => "#,##0.###",
            "percent" => "#,##0%",
            "scientific" => "#E0"
          }

          fallback_patterns.each do |type, pattern|
            formats[type] = pattern if formats[type].nil? || formats[type].empty?
          end
        end

        private def apply_fallback_symbols(symbols)
          # Default symbols from root locale when not specified
          fallback_symbols = {
            "decimal" => ".",
            "group" => ",",
            "minus_sign" => "-",
            "plus_sign" => "+",
            "percent_sign" => "%",
            "per_mille" => "‰",
            "exponential" => "E",
            "infinity" => "∞",
            "nan" => "NaN"
          }

          fallback_symbols.each do |key, symbol|
            symbols[key] = symbol if symbols[key].nil? || symbols[key].empty?
          end
        end

        private def extract_currency_fractions
          # Currency fractions come from supplemental data, not individual locale files
          # We need to read from supplemental/supplementalData.xml
          supplemental_path = File.join(source_dir, "common", "supplemental", "supplementalData.xml")

          return {} unless File.exist?(supplemental_path)

          fractions = {}

          begin
            supplemental_doc = REXML::Document.new(File.read(supplemental_path))

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
            log "Warning: Could not extract currency fractions: #{e.message}"
          end

          fractions
        end

        private def extract_currency_formats(xml_doc, formats)
          currency_formats = {"standard" => formats["currency"]}

          # Check for accounting pattern
          xpath = "ldml/numbers/currencyFormats[@numberSystem='latn']/currencyFormatLength[not(@type)]/currencyFormat[@type='accounting']/pattern[not(@type)]"
          accounting_element = xml_doc.elements[xpath]
          currency_formats["accounting"] = accounting_element.text if accounting_element

          currency_formats
        end

        private def merge_locale_and_root_currencies(xml_doc)
          # Start with comprehensive root currencies
          currencies = load_root_currencies

          # Override with locale-specific currency data - this preserves previous behavior
          # where locale-specific currency symbols took precedence over root symbols
          locale_currencies = extract_currencies(xml_doc)
          locale_currencies.each do |code, locale_data|
            if currencies[code]
              currencies[code].merge!(locale_data)
            else
              currencies[code] = locale_data
            end
          end

          currencies
        end

        private def extract_all_currencies
          # Fallback method - just use root currencies
          load_root_currencies
        end

        private def load_root_currencies
          root_path = File.join(source_dir, "common", "main", "root.xml")
          return {} unless File.exist?(root_path)

          currencies = {}

          begin
            root_doc = REXML::Document.new(File.read(root_path))

            # Get all currency codes and symbols from root
            root_doc.elements.each("ldml/numbers/currencies/currency") do |currency|
              code = currency.attributes["type"]
              next unless code

              currency_data = {}

              # Get symbol (prefer non-narrow)
              symbol_element = currency.elements["symbol[not(@alt)]"] || currency.elements["symbol"]
              if symbol_element
                currency_data["symbol"] = symbol_element.text
              end

              # Get display names
              display_names = {}
              currency.elements.each("displayName") do |name|
                count = name.attributes["count"]
                if count
                  display_names[count] = name.text
                else
                  display_names["other"] = name.text
                  display_names["one"] = name.text unless display_names.key?("one")
                end
              end
              currency_data["display_names"] = display_names unless display_names.empty?

              currencies[code] = currency_data unless currency_data.empty?
            end
          rescue => e
            log "Warning: Could not extract root currencies: #{e.message}"
          end

          currencies
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

            # Display names with nested structure
            display_names = {}
            currency.elements.each("displayName") do |name|
              count = name.attributes["count"]
              if count
                display_names[count] = name.text
              else
                display_names["other"] = name.text # Default to "other" for consistency
                # Also set specific forms if no count attribute
                display_names["one"] = name.text unless display_names.key?("one")
              end
            end

            currency_data["display_names"] = display_names unless display_names.empty?
            currencies[code] = currency_data unless currency_data.empty?
          end

          currencies
        end
      end
    end
  end
end
