# frozen_string_literal: true

require_relative "multi_locale"

module Foxtail
  module CLDR
    module Extractor
      # CLDR plural rules data extractor
      #
      # Extracts plural rule expressions from CLDR supplemental XML data for number
      # categorization, then writes structured YAML files for use by the plural
      # rules repository.
      #
      # @see https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules
      class PluralRules < MultiLocale
        def initialize(source_dir:, output_dir:)
          super
          @supplemental_rules_cache = nil
        end

        # Override extract to load supplemental data first, then use parent class logic
        def extract
          load_supplemental_rules_cache

          CLDR.logger.info "Extracting #{inflector.demodulize(self.class)} from supplemental data for #{@supplemental_rules_cache.size} locales..."

          @supplemental_rules_cache.keys.each_slice(100).with_index do |batch, batch_index|
            batch.each do |locale_id|
              extract_locale(locale_id)
            end

            # Progress indicator after each batch
            processed_count = (batch_index + 1) * 100
            # Don't exceed total count for the last batch
            processed_count = [processed_count, @supplemental_rules_cache.size].min
            CLDR.logger.info "Progress: #{processed_count}/#{@supplemental_rules_cache.size} locales processed"
          end

          # Clean up obsolete files after processing all locales
          cleanup_obsolete_files

          CLDR.logger.info "#{inflector.demodulize(self.class)} extraction complete (#{@supplemental_rules_cache.size} locales)"
        end

        # Override to use supplemental cache instead of individual XML files
        private def load_raw_locale_data(locale_id)
          load_supplemental_rules_cache unless @supplemental_rules_cache
          @supplemental_rules_cache[locale_id]
        end

        # Not used for plural rules - we override load_raw_locale_data instead
        private def extract_data_from_xml(_xml_doc)
          raise NotImplementedError, "PluralRules uses supplemental data, not individual locale XML files"
        end

        private def load_supplemental_rules_cache
          return if @supplemental_rules_cache

          supplemental_path = @source_dir + "common" + "supplemental" + "plurals.xml"
          doc = REXML::Document.new(supplemental_path.read)
          @supplemental_rules_cache = extract_all_locales_from_supplemental(doc)
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

            # Assign these rules to all locales in the group with proper structure
            locales.each do |locale_id|
              locale_rules_map[locale_id] = {"plural_rules" => plural_rules.dup}
            end
          end

          locale_rules_map
        end

        private def data?(data)
          return false unless data.is_a?(Hash)
          return false unless data["plural_rules"].is_a?(Hash)

          !data["plural_rules"].empty?
        end

        # Override extract_differences with nuanced plural rules logic
        # Preserve complete rule sets only for locales with multiple categories
        private def extract_differences(child_data, parent_data)
          diff = super

          # Special handling for plural rules: preserve 'other' only if there are other keys
          if child_data.is_a?(Hash) && child_data["plural_rules"].is_a?(Hash)
            plural_rules = child_data["plural_rules"]

            # If there are keys other than 'other', preserve the complete rule set including 'other'
            if plural_rules.keys.size > 1 || !plural_rules.key?("other")
              diff["plural_rules"] ||= {}
              # Copy all rules including 'other' to ensure completeness
              plural_rules.each do |key, value|
                diff["plural_rules"][key] = value
              end
            end
            # If only 'other' exists, let the parent logic remove it (file won't be created)
          end

          diff
        end
      end
    end
  end
end
