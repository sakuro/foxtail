# frozen_string_literal: true

module Foxtail
  module CLDR
    module Extractor
      # Extracts CLDR locale alias mappings from supplemental metadata
      class LocaleAliases < Base
        # Extract all locale aliases from supplemental metadata
        def extract_all
          validate_source_directory
          extract_locale_aliases
        end

        # Single file extractor - no cleanup needed
        private def cleanup_obsolete_files
          # No-op: locale aliases generates a single file, no cleanup needed
        end

        private def extract_locale_aliases
          CLDR.logger.info "Extracting LocaleAliases..."

          aliases = load_locale_aliases_from_supplemental

          return if aliases.empty?

          write_alias_data(aliases)
          CLDR.logger.info "LocaleAliases extraction complete (#{aliases.size} aliases)"
        end

        private def load_locale_aliases_from_supplemental
          # Load from supplementalMetadata.xml (traditional aliases)
          aliases = load_traditional_aliases

          # Load from likelySubtags.xml (locale expansion rules)
          likely_aliases = load_likely_subtag_aliases

          # Merge both sources (traditional aliases take precedence)
          aliases.merge(likely_aliases)
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

        private def write_alias_data(aliases)
          file_path = @output_dir + "locale_aliases.yml"

          yaml_data = {
            "generated_at" => Time.now.utc.iso8601,
            "cldr_version" => Foxtail::CLDR::SOURCE_VERSION,
            "locale_aliases" => aliases
          }

          # Skip writing if only generated_at differs
          if should_skip_write?(file_path, yaml_data)
            return
          end

          file_path.write(yaml_data.to_yaml)
          CLDR.logger.debug "Wrote LocaleAliases to #{relative_path(file_path)}"
        end

        private def validate_source_directory
          supplemental_dir = @source_dir + "common" + "supplemental"

          return if supplemental_dir.exist?

          raise ArgumentError, "CLDR supplemental directory not found: #{supplemental_dir}"
        end

        # Template method implementations (not used for supplemental data)
        private def extract_data_from_xml(_xml_doc)
          # Not used - we override extract_all instead
          nil
        end

        private def data?(_data)
          # Not used - we override extract_all instead
          false
        end

        private def write_data(_locale_id, _data)
          # Not used - we override extract_all instead
        end
      end
    end
  end
end
