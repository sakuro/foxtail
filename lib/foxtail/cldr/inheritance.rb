# frozen_string_literal: true

require "rexml/document"
require "singleton"
require "yaml"

module Foxtail
  module CLDR
    # Handles CLDR locale inheritance chain resolution and data merging
    # Implements the complete CLDR inheritance model:
    # root → language → language_Script → language_Territory → language_Script_Territory
    class Inheritance
      include Singleton

      def initialize
        @parent_locales = nil
      end

      # Parse a locale identifier and return the complete inheritance chain
      # @param locale [String] Locale identifier (e.g., "en_US", "zh_Hans_CN")
      # @return [Array<String>] Inheritance chain from most specific to root
      def resolve_inheritance_chain(locale)
        chain = [locale]

        # Handle different locale patterns
        case locale
        when /^([a-z]{2,3})_([A-Z][a-z]{3})_([A-Z]{2})$/
          # language_Script_Territory (e.g., zh_Hans_CN)
          language = $1
          script = $2
          _ = $3
          chain << "#{language}_#{script}"    # language_Script
          chain << language                   # language
        when /^([a-z]{2,3})_([A-Z][a-z]{3}|[A-Z]{2})$/
          # language_Script (e.g., zh_Hans) or language_Territory (e.g., en_US)
          language = $1
          chain << language # language
        end

        # Always end with root unless we're already root
        chain << "root" unless locale == "root"

        chain
      end

      # Load parent locale mappings from CLDR supplemental data
      # @param source_dir [String] Path to CLDR source directory
      # @return [Hash] Mapping of locale to parent locale
      def load_parent_locales(source_dir)
        supplemental_path = File.join(source_dir, "common", "supplemental", "supplementalData.xml")

        return {} unless File.exist?(supplemental_path)

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
          log "Warning: Could not load parent locales: #{e.message}"
        end

        parents
      end

      # Load locale alias mappings from CLDR supplemental data
      # @param source_dir [String] Path to CLDR source directory
      # @return [Hash] Mapping of alias locale to canonical locale
      def load_locale_aliases(data_dir)
        aliases_path = File.join(data_dir, "locale_aliases.yml")

        return {} unless File.exist?(aliases_path)

        begin
          yaml_data = YAML.load_file(aliases_path)
          aliases = yaml_data["locale_aliases"] || {}
          log "Loaded #{aliases.size} locale aliases from #{aliases_path}"
          aliases
        rescue => e
          log "Warning: Could not load locale aliases from #{aliases_path}: #{e.message}"
          {}
        end
      end

      # Resolve locale aliases to canonical form
      # @param locale_id [String] The locale identifier (may be an alias)
      # @param aliases [Hash] Mapping of alias to canonical locale
      # @return [String] The canonical locale identifier
      def resolve_locale_alias(locale_id, aliases)
        return locale_id if aliases.empty?

        # First try to resolve the entire locale_id as an alias
        if aliases[locale_id]
          result = aliases[locale_id]
          log "Full locale alias resolution: #{locale_id} -> #{result}"
          return result
        end

        # Handle complex locale identifiers by resolving each component
        if locale_id.include?("_")
          parts = locale_id.split("_")
          log "Resolving compound locale #{locale_id}: parts = #{parts}"
          resolved_parts = parts.map {|part|
            resolved = aliases[part] || part
            log "  #{part} -> #{resolved}"
            resolved
          }
          result = resolved_parts.join("_")
          log "Final resolved compound locale: #{locale_id} -> #{result}"
        else
          result = aliases[locale_id] || locale_id
          log "Simple locale resolution: #{locale_id} -> #{result} (found: #{aliases.key?(locale_id)})"
        end
        result
      end

      # Resolve inheritance chain using CLDR parent locale data
      # @param locale [String] Locale identifier
      # @param parent_locales [Hash] Parent locale mappings from supplemental data
      # @return [Array<String>] Complete inheritance chain
      def resolve_inheritance_chain_with_parents(locale, parent_locales)
        chain = []
        current = locale
        seen = Set.new

        # Follow parent chain to avoid infinite loops
        while current && !seen.include?(current)
          chain << current
          seen.add(current)

          # Use explicit parent from supplemental data first
          if parent_locales[current]
            current = parent_locales[current]
          else
            # Fall back to algorithmic parent resolution
            algorithmic_chain = resolve_inheritance_chain(current)
            # Get the next parent (skip current locale)
            current = algorithmic_chain[1] if algorithmic_chain.length > 1
          end

          break if current == "root"
        end

        # Always end with root unless we started with root
        chain << "root" unless locale == "root" || chain.include?("root")

        chain
      end

      # Merge data following CLDR inheritance rules
      # Child data takes precedence over parent data
      # @param parent_data [Hash] Data from parent locale
      # @param child_data [Hash] Data from child locale
      # @return [Hash] Merged data with child overrides
      def merge_data(parent_data, child_data)
        return child_data.dup if parent_data.nil? || parent_data.empty?
        return parent_data.dup if child_data.nil? || child_data.empty?

        merged = parent_data.dup

        child_data.each do |key, value|
          merged[key] = if merged[key].is_a?(Hash) && value.is_a?(Hash)
                          # Recursively merge nested hashes
                          merge_data(merged[key], value)
                        else
                          # Child value overrides parent value
                          value
                        end
        end

        merged
      end

      # Load and merge data for a locale following complete inheritance chain
      # @param locale [String] Target locale
      # @param source_dir [String] Path to CLDR source directory
      # @param extractor [BaseExtractor] Extractor instance for data extraction
      # @param parent_locales [Hash] Optional parent locale mappings
      # @return [Hash] Fully inherited and merged data
      def load_inherited_data(locale, source_dir, extractor, parent_locales={})
        chain = if parent_locales.empty?
                  resolve_inheritance_chain(locale)
                else
                  resolve_inheritance_chain_with_parents(locale, parent_locales)
                end

        # Start with empty data and merge from root to specific
        merged_data = {}

        # Process inheritance chain in reverse (root first)
        chain.reverse_each do |chain_locale|
          locale_data = load_locale_data(chain_locale, source_dir, extractor)
          next if locale_data.nil?

          merged_data = merge_data(merged_data, locale_data)
        end

        merged_data
      end

      # Load raw data for a single locale without inheritance
      # @param locale [String] Locale identifier
      # @param source_dir [String] Path to CLDR source directory
      # @param extractor [BaseExtractor] Extractor instance for data extraction
      # @return [Hash, nil] Raw locale data or nil if not found
      def load_locale_data(locale, source_dir, extractor)
        xml_path = File.join(source_dir, "common", "main", "#{locale}.xml")

        return nil unless File.exist?(xml_path)

        begin
          doc = REXML::Document.new(File.read(xml_path))
          extractor.__send__(:extract_data_from_xml, doc)
        rescue => e
          log "Warning: Could not load data for locale #{locale}: #{e.message}"
          nil
        end
      end

      # Progress logging method for testing support
      def log(message)
        puts message
      end
    end
  end
end
