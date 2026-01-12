# frozen_string_literal: true

require "icu4x"
require "singleton"

module Fantail
  # Singleton cache for ICU4X formatter and rules instances.
  #
  # ICU4X formatters and rules internally load and parse locale data,
  # making instance creation non-trivial. This cache stores instances
  # keyed by locale and options to avoid repeated instantiation.
  #
  # @example
  #   cache = Fantail::ICU4XCache.instance
  #   formatter = cache.number_formatter(locale)
  #   formatter.format(1234)  #=> "1,234"
  class ICU4XCache
    include Singleton

    def initialize
      @number_formatters = {}
      @datetime_formatters = {}
      @plural_rules = {}
      @number_formatters_mutex = Mutex.new
      @datetime_formatters_mutex = Mutex.new
      @plural_rules_mutex = Mutex.new
    end

    # Returns a cached ICU4X::NumberFormat instance.
    #
    # @param locale [ICU4X::Locale] The locale for formatting
    # @param options [Hash] Formatting options passed to ICU4X::NumberFormat.new
    # @return [ICU4X::NumberFormat] Cached formatter instance
    def number_formatter(locale, **options)
      key = [locale, options]
      @number_formatters_mutex.synchronize do
        @number_formatters[key] ||= ICU4X::NumberFormat.new(locale, **options)
      end
    end

    # Returns a cached ICU4X::DateTimeFormat instance.
    #
    # @param locale [ICU4X::Locale] The locale for formatting
    # @param options [Hash] Formatting options passed to ICU4X::DateTimeFormat.new
    # @return [ICU4X::DateTimeFormat] Cached formatter instance
    def datetime_formatter(locale, **options)
      key = [locale, options]
      @datetime_formatters_mutex.synchronize do
        @datetime_formatters[key] ||= ICU4X::DateTimeFormat.new(locale, **options)
      end
    end

    # Returns a cached ICU4X::PluralRules instance.
    #
    # @param locale [ICU4X::Locale] The locale for plural rules
    # @param type [Symbol] Plural rule type (:cardinal or :ordinal)
    # @return [ICU4X::PluralRules] Cached rules instance
    def plural_rules(locale, type: :cardinal)
      key = [locale, type]
      @plural_rules_mutex.synchronize do
        @plural_rules[key] ||= ICU4X::PluralRules.new(locale, type:)
      end
    end
  end
end
