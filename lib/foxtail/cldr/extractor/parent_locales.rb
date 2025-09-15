# frozen_string_literal: true

require "rexml/document"
require "yaml"

module Foxtail
  module CLDR
    module Extractor
      # Extracts parent locale mappings from CLDR supplemental data
      class ParentLocales < Base
        # Extract parent locale mappings for all components
        # @return [Hash] Parent locale mappings
        def extract_all
          CLDR.logger.info "Extracting ParentLocales..."

          parent_locales_data = {
            "generated_at" => Time.now.utc.iso8601,
            "cldr_version" => ENV.fetch("CLDR_VERSION", "46"),
            "parent_locales" => extract_parent_locales_data
          }

          output_path = File.join(@output_dir, "parent_locales.yml")
          FileUtils.mkdir_p(File.dirname(output_path))

          # Skip writing if only generated_at differs
          if should_skip_write?(output_path, parent_locales_data)
            return parent_locales_data
          end

          File.write(output_path, YAML.dump(parent_locales_data))
          CLDR.logger.info "ParentLocales extraction complete"

          parent_locales_data
        end

        # Load parent locale mappings directly from CLDR source (ParentLocales extractor only)
        def load_parent_locales_from_source
          supplemental_path = File.join(@source_dir, "common", "supplemental", "supplementalData.xml")

          parents = {}

          begin
            doc = REXML::Document.new(File.read(supplemental_path))

            # Extract parent locale relationships
            doc.elements.each("supplementalData/parentLocales/parentLocale") do |parent_element|
              parent = parent_element.attributes["parent"]
              locales_attr = parent_element.attributes["locales"]

              next unless parent && locales_attr

              # Parse locale list: "en_AU en_CA" -> ["en_AU", "en_CA"]
              locales = locales_attr.split(/\s+/)
              locales.each do |locale|
                parents[locale] = parent
              end
            end
          rescue => e
            CLDR.logger.warn "Could not load parent locales: #{e.message}"
          end

          parents
        end
        # Single file extractor - no cleanup needed
        private def cleanup_obsolete_files
          # No-op: parent locales generates a single file, no cleanup needed
        end

        private def extract_parent_locales_data
          load_parent_locales_from_source
        end
      end
    end
  end
end
