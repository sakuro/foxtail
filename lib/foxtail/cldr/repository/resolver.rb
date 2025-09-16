# frozen_string_literal: true

require "yaml"

module Foxtail
  module CLDR
    module Repository
      # CLDR locale data resolver
      # Resolves missing data by traversing inheritance chain at runtime
      class Resolver
        def initialize(locale, data_dir: nil)
          @locale = locale
          @locale_id = locale.respond_to?(:to_simple) ? locale.to_simple.to_s : locale.to_s
          @data_dir = data_dir ? Pathname(data_dir) : Foxtail.cldr_dir
          @inheritance = Inheritance.instance
          @cache = {}
          @loaded_locales = {}
          @locale_aliases = nil
          @parent_locales = nil
          @inheritance_chain = nil

          # Resolve locale alias to canonical form
          @locale_id = resolve_canonical_locale(@locale_id)
        end

        # Resolve a data path using inheritance chain
        # @param data_path [String] Dot-separated path (e.g., "currencies.USD.symbol")
        # @param data_type [String] Data type (e.g., "number_formats", "datetime_formats")
        # @return [Object] Resolved value or nil if not found
        def resolve(data_path, data_type)
          cache_key = [@locale_id, data_type, data_path]
          return @cache[cache_key] if @cache.key?(cache_key)

          value = resolve_with_inheritance(data_path, data_type)
          @cache[cache_key] = value
        end

        private def resolve_with_inheritance(data_path, data_type)
          chain = inheritance_chain

          # For nested structures, we need to merge data from all levels
          # Start from root and let child data override parent data
          merged_value = nil

          chain.reverse_each do |parent_locale|
            data = load_locale_data(parent_locale, data_type)
            next unless data

            value = extract_nested_value(data, data_path)
            next unless value_exists?(value)

            merged_value = if value.is_a?(Hash) && merged_value.is_a?(Hash)
                             # Merge parent data with child data (child wins)
                             deep_merge(merged_value, value)
                           else
                             value
                           end
          end

          merged_value
        end

        private def deep_merge(parent_hash, child_hash)
          result = parent_hash.dup

          child_hash.each do |key, value|
            result[key] = if result[key].is_a?(Hash) && value.is_a?(Hash)
                            deep_merge(result[key], value)
                          else
                            value
                          end
          end

          result
        end

        private def inheritance_chain
          return @inheritance_chain if @inheritance_chain

          @inheritance_chain = @inheritance.resolve_inheritance_chain_with_parents(@locale_id, parent_locale_ids)
          CLDR.logger.debug "Inheritance chain for #{@locale_id}: #{@inheritance_chain}"
          @inheritance_chain
        end

        private def parent_locale_ids
          @parent_locale_ids ||= begin
            @inheritance.load_parent_locale_ids(@data_dir)
          rescue ArgumentError => e
            CLDR.logger.warn "#{e.message}. Falling back to algorithmic inheritance."
            {}
          end
        end

        private def load_locale_data(locale_id, data_type)
          cache_key = [locale_id, data_type]
          return @loaded_locales[cache_key] if @loaded_locales.key?(cache_key)

          file_path = @data_dir + locale_id + "#{data_type}.yml"
          CLDR.logger.debug "Attempting to load: #{file_path}"

          data = if file_path.exist?
                   begin
                     loaded_data = YAML.load_file(file_path.to_s)
                     CLDR.logger.debug "Successfully loaded #{file_path} for locale #{locale_id}"
                     loaded_data
                   rescue => e
                     CLDR.logger.warn "Could not load #{file_path}: #{e.message}"
                     nil
                   end
                 else
                   CLDR.logger.debug "File does not exist: #{file_path}"
                   nil
                 end

          @loaded_locales[cache_key] = data
        end

        private def extract_nested_value(data, path)
          return nil unless data.is_a?(Hash)

          keys = path.split(".")
          current = data

          keys.each do |key|
            return nil unless current.is_a?(Hash) && current.key?(key)

            current = current[key]
          end

          current
        end

        private def value_exists?(value)
          !value.nil? && !(value.is_a?(String) && value.empty?)
        end

        # Resolve locale identifier to canonical form using CLDR aliases
        # @param locale_id [String] Original locale identifier (may be an alias)
        # @return [String] Canonical locale identifier
        private def resolve_canonical_locale(locale_id)
          aliases = load_locale_aliases_if_needed
          CLDR.logger.debug "Loaded #{aliases.size} locale aliases: #{aliases.keys.first(5)}"
          return locale_id if aliases.empty?

          canonical = @inheritance.resolve_locale_alias(locale_id, aliases)

          if canonical == locale_id
            CLDR.logger.debug "No alias found for: #{locale_id}"
          else
            CLDR.logger.debug "Resolved locale alias: #{locale_id} -> #{canonical}"
          end

          canonical
        end

        # Load locale aliases from CLDR source if available, with caching
        # @return [Hash] Locale aliases mapping
        private def load_locale_aliases_if_needed
          return @locale_aliases if @locale_aliases

          @locale_aliases = @inheritance.load_locale_aliases(@data_dir)
        end
      end
    end
  end
end
