# frozen_string_literal: true

require "pathname"
require "singleton"
require "yaml"

module Foxtail
  module CLDR
    module Repository
      # Handles CLDR locale inheritance chain resolution and data merging
      # Implements the complete CLDR inheritance model:
      # root → language → language_Script → language_Territory → language_Script_Territory
      class Inheritance
        include Singleton

        def initialize
          @parent_locales = nil
        end

        # Parse a locale identifier and return the complete inheritance chain
        # @param locale_id [String] Locale identifier (e.g., "en_US", "zh_Hans_CN")
        # @return [Array<String>] Inheritance chain from most specific to root
        def resolve_inheritance_chain(locale_id)
          chain = [locale_id]

          # Handle different locale patterns
          case locale_id
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
          chain << "root" unless locale_id == "root"

          chain
        end

        # Load parent locale ID mappings from extracted YAML data
        # @param data_dir [String] Path to extracted CLDR data directory
        # @return [Hash] Mapping of locale ID to parent locale ID
        # @raise [ArgumentError] if parent_locales.yml is not found
        def load_parent_locale_ids(data_dir)
          parent_locales_path = data_dir + "parent_locales.yml"

          unless parent_locales_path.exist?
            raise ArgumentError, "Parent locales data not found: #{parent_locales_path}. " \
                                 "Run parent locales extraction first."
          end

          begin
            yaml_data = YAML.load_file(parent_locales_path.to_s)
            parent_locale_ids = yaml_data["parent_locales"] || {}

            # Log only on first load
            unless @parent_locales_logged
              relative_path = begin
                parent_locales_path.relative_path_from(data_dir).to_s
              rescue
                parent_locales_path.to_s
              end
              CLDR.logger.debug "Loaded #{parent_locale_ids.size} parent locale mappings from #{relative_path}"
              @parent_locales_logged = true
            end

            parent_locale_ids
          rescue => e
            raise ArgumentError, "Could not load parent locales from #{parent_locales_path}: #{e.message}"
          end
        end

        # Load locale alias mappings from CLDR supplemental data
        # @param data_dir [String] Path to CLDR data directory
        # @return [Hash] Mapping of alias locale to canonical locale
        def load_locale_aliases(data_dir)
          aliases_path = data_dir + "locale_aliases.yml"

          return {} unless aliases_path.exist?

          begin
            yaml_data = YAML.load_file(aliases_path.to_s)
            aliases = yaml_data["locale_aliases"] || {}
            CLDR.logger.debug "Loaded #{aliases.size} locale aliases from #{aliases_path}"
            aliases
          rescue => e
            CLDR.logger.warn "Could not load locale aliases from #{aliases_path}: #{e.message}"
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
            CLDR.logger.debug "Full locale alias resolution: #{locale_id} -> #{result}"
            return result
          end

          # Handle complex locale identifiers by resolving each component
          if locale_id.include?("_")
            parts = locale_id.split("_")
            CLDR.logger.debug "Resolving compound locale #{locale_id}: parts = #{parts}"
            resolved_parts = parts.map {|part|
              resolved = aliases[part] || part
              CLDR.logger.debug "  #{part} -> #{resolved}"
              resolved
            }
            result = resolved_parts.join("_")
            CLDR.logger.debug "Final resolved compound locale: #{locale_id} -> #{result}"
          else
            result = aliases[locale_id] || locale_id
            CLDR.logger.debug "Simple locale resolution: #{locale_id} -> #{result} (found: #{aliases.key?(locale_id)})"
          end
          result
        end

        # Resolve inheritance chain using CLDR parent locale data
        # @param locale_id [String] Locale identifier
        # @param parent_locale_ids [Hash] Parent locale ID mappings from supplemental data
        # @return [Array<String>] Complete inheritance chain
        def resolve_inheritance_chain_with_parents(locale_id, parent_locale_ids)
          chain = []
          current = locale_id
          seen = Set.new

          # Follow parent chain to avoid infinite loops
          while current && !seen.include?(current)
            chain << current
            seen.add(current)

            # Use explicit parent from supplemental data first
            if parent_locale_ids[current]
              current = parent_locale_ids[current]
            else
              # Fall back to algorithmic parent resolution
              algorithmic_chain = resolve_inheritance_chain(current)
              # Get the next parent (skip current locale)
              current = algorithmic_chain[1] if algorithmic_chain.length > 1
            end

            break if current == "root"
          end

          # Always end with root unless we started with root
          chain << "root" unless locale_id == "root" || chain.include?("root")

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
      end
    end
  end
end
