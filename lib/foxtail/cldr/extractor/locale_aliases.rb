# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractor
      # CLDR locale aliases data extractor
      #
      # Extracts locale alias mappings from CLDR supplemental metadata including
      # language aliases, territory aliases, and script aliases, then writes a
      # single structured YAML file for use by locale resolution.
      #
      # @see https://unicode.org/reports/tr35/tr35-core.html#Locale_Inheritance
      class LocaleAliases < SingleFile
        # Extract all locale aliases from supplemental metadata
        private def extract_data
          # Load from supplementalMetadata.xml (traditional aliases)
          traditional_aliases = load_traditional_aliases

          # Load from likelySubtags.xml (locale expansion rules)
          likely_aliases = load_likely_subtag_aliases

          # Merge both sources (traditional aliases take precedence)
          locale_aliases = traditional_aliases.merge(likely_aliases)

          {"locale_aliases" => locale_aliases}
        end

        private def load_traditional_aliases
          supplemental_path = @source_dir + "common" + "supplemental" + "supplementalMetadata.xml"

          aliases = {}

          begin
            doc = REXML::Document.new(supplemental_path.read)

            # Extract language aliases
            doc.elements.each("supplementalData/metadata/alias/languageAlias") do |alias_element|
              type = alias_element.attributes["type"]
              replacement = alias_element.attributes["replacement"]
              reason = alias_element.attributes["reason"]

              next unless type && replacement
              next if reason == "overlong" # Skip overlong forms

              aliases[type] = replacement
            end

            # Extract territory aliases
            doc.elements.each("supplementalData/metadata/alias/territoryAlias") do |alias_element|
              type = alias_element.attributes["type"]
              replacement = alias_element.attributes["replacement"]
              reason = alias_element.attributes["reason"]

              next unless type && replacement
              next if reason == "overlong"
              next if replacement.include?(" ") # Skip multi-territory replacements

              aliases[type] = replacement
            end

            # Extract script aliases
            doc.elements.each("supplementalData/metadata/alias/scriptAlias") do |alias_element|
              type = alias_element.attributes["type"]
              replacement = alias_element.attributes["replacement"]
              reason = alias_element.attributes["reason"]

              next unless type && replacement
              next if reason == "overlong"

              aliases[type] = replacement
            end
          rescue => e
            CLDR.logger.warn "Could not load traditional aliases: #{e.message}"
          end

          unless aliases.empty?
            CLDR.logger.debug "Loaded #{aliases.size} traditional aliases from supplementalMetadata.xml"
          end
          aliases
        end

        private def load_likely_subtag_aliases
          likely_subtags_path = @source_dir + "common" + "supplemental" + "likelySubtags.xml"

          aliases = {}

          begin
            doc = REXML::Document.new(likely_subtags_path.read)

            # Extract likely subtags that can serve as aliases
            doc.elements.each("supplementalData/likelySubtags/likelySubtag") do |subtag_element|
              from = subtag_element.attributes["from"]
              to = subtag_element.attributes["to"]

              next unless from && to
              next if from == to # Skip identity mappings

              # Only include mappings that look like useful aliases
              # (e.g., zh_TW -> zh_Hant_TW, not zh -> zh_Hans_CN)
              if from.include?("_") && to.include?("_")
                aliases[from] = to
              end
            end
          rescue => e
            CLDR.logger.warn "Could not load likely subtags: #{e.message}"
          end

          unless aliases.empty?
            CLDR.logger.debug "Loaded #{aliases.size} likely subtag aliases from likelySubtags.xml"
          end
          aliases
        end
      end
    end
  end
end
