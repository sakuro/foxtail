# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractor
      # Extracts plural rules from CLDR supplemental XML data and writes to YAML files
      class PluralRules < Base
        # Override extract_all since plural rules are in supplemental data, not individual locale files
        def extract_all
          validate_source_directory

          supplemental_path = @source_dir + "common" + "supplemental" + "plurals.xml"
          unless supplemental_path.exist?
            CLDR.logger.warn "Plural rules file not found: #{supplemental_path}"
            return
          end

          CLDR.logger.info "Extracting PluralRules from supplemental data..."

          doc = REXML::Document.new(supplemental_path.read)
          locale_rules_map = extract_all_locales_from_supplemental(doc)

          locale_rules_map.each do |locale_id, rules_data|
            next unless data?(rules_data)

            write_data(locale_id, rules_data)
          end

          CLDR.logger.info "PluralRules extraction complete (#{locale_rules_map.size} locales)"
        end

        # Override extract_locale since plural rules come from supplemental data
        def extract_locale(locale_id)
          validate_source_directory

          supplemental_path = @source_dir + "common" + "supplemental" + "plurals.xml"
          unless supplemental_path.exist?
            CLDR.logger.warn "Plural rules file not found: #{supplemental_path}"
            return
          end

          doc = REXML::Document.new(supplemental_path.read)
          locale_rules_map = extract_all_locales_from_supplemental(doc)

          if locale_rules_map.key?(locale_id)
            rules_data = locale_rules_map[locale_id]
            if data?(rules_data)
              write_data(locale_id, rules_data)
            end
          else
            CLDR.logger.warn "No plural rules found for locale: #{locale_id}"
          end
        end

        # Not used for plural rules - they come from supplemental data
        private def extract_data_from_xml(_xml_doc)
          raise NotImplementedError, "Use extract_all_locales_from_supplemental for plural rules"
        end

        private def extract_all_locales_from_supplemental(doc)
          locale_rules_map = {}

          doc.elements.each("supplementalData/plurals[@type='cardinal']/pluralRules") do |rules_element|
            locales_attr = rules_element.attributes["locales"]
            next unless locales_attr

            # Parse locale list: "en fr de" -> ["en", "fr", "de"]
            locales = locales_attr.split(/\s+/)

            # Extract rules for this group
            plural_rules = {}
            rules_element.elements.each("pluralRule") do |rule|
              count = rule.attributes["count"]
              next unless count && rule.text

              # Strip @integer and @decimal examples, keep only the condition
              condition = rule.text.strip.gsub(/@(integer|decimal)[^@]*/, "").strip
              plural_rules[count] = condition
            end

            # Assign these rules to all locales in the group
            locales.each do |locale_id|
              locale_rules_map[locale_id] = plural_rules.dup
            end
          end

          locale_rules_map
        end

        private def data?(data)
          data.is_a?(Hash) && !data.empty?
        end

        private def write_data(locale_id, data)
          # Wrap rules in plural_rules key to match expected structure
          structured_data = {"plural_rules" => data}
          write_yaml_file(locale_id, "plural_rules.yml", structured_data)
        end
      end
    end
  end
end
