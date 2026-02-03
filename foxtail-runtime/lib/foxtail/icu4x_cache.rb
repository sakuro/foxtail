# frozen_string_literal: true

require "dry/core/cache"
require "singleton"

module Foxtail
  # Singleton cache for ICU4X formatter and rules instances.
  #
  # ICU4X formatters and rules internally load and parse locale data,
  # making instance creation non-trivial. This cache stores instances
  # keyed by locale and options to avoid repeated instantiation.
  #
  # Thread safety is provided by Dry::Core::Cache, which uses
  # Concurrent::Map internally.
  #
  # @example
  #   cache = Foxtail::ICU4XCache.instance
  #   formatter = cache.number_formatter(locale)
  #   formatter.format(1234)  #=> "1,234"
  class ICU4XCache
    extend Dry::Core::Cache
    include Singleton

    # Returns a cached ICU4X::NumberFormat instance.
    #
    # @param locale [ICU4X::Locale] The locale for formatting
    # @param options [Hash] Formatting options passed to ICU4X::NumberFormat.new
    # @return [ICU4X::NumberFormat] Cached formatter instance
    def number_formatter(locale, **options)
      self.class.fetch_or_store(:number_formatter, locale, options) do
        ICU4X::NumberFormat.new(locale, **options)
      end
    end

    # Returns a cached ICU4X::DateTimeFormat instance.
    #
    # @param locale [ICU4X::Locale] The locale for formatting
    # @param options [Hash] Formatting options passed to ICU4X::DateTimeFormat.new
    # @return [ICU4X::DateTimeFormat] Cached formatter instance
    def datetime_formatter(locale, **options)
      self.class.fetch_or_store(:datetime_formatter, locale, options) do
        ICU4X::DateTimeFormat.new(locale, **options)
      end
    end

    # Returns a cached ICU4X::PluralRules instance.
    #
    # @param locale [ICU4X::Locale] The locale for plural rules
    # @param type [Symbol] Plural rule type (:cardinal or :ordinal)
    # @return [ICU4X::PluralRules] Cached rules instance
    def plural_rules(locale, type: :cardinal)
      self.class.fetch_or_store(:plural_rules, locale, type) do
        ICU4X::PluralRules.new(locale, type:)
      end
    end
  end
end
