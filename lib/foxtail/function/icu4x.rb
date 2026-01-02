# frozen_string_literal: true

require "icu4x"
require "icu4x/data/recommended"

module Foxtail
  module Function
    # ICU4X-based formatters using the icu4x gem
    # Named Icu4xBackend to avoid namespace conflict with the icu4x gem's ICU4X module
    module Icu4xBackend
      # ICU4X NumberFormat implementation
      class NumberFormat
        # Initialize formatter with locale and options
        # @param locale [Locale::Tag::Simple] Locale for formatting
        # @param options [Hash] Formatting options
        def initialize(locale:, **options)
          @locale = convert_locale(locale)
          @options = convert_options(options)
        end

        # Format number using ICU4X
        # @param value [Numeric] Number to format
        # @return [String] Formatted number
        def call(value) = ::ICU4X::NumberFormat.new(@locale, **@options).format(value)

        # Convert Locale::Tag to ICU4X::Locale
        # @param locale [Locale::Tag::Simple, String] Locale to convert
        # @return [ICU4X::Locale] ICU4X locale object
        private def convert_locale(locale)
          locale_str = locale.respond_to?(:to_rfc) ? locale.to_rfc : locale.to_s
          ::ICU4X::Locale.parse(locale_str)
        end

        alias format call

        # Convert FTL/JS style options to icu4x options
        # @param options [Hash] FTL/JS style options (camelCase)
        # @return [Hash] icu4x style options (snake_case with symbols)
        private def convert_options(options)
          result = {}

          options.each do |key, value|
            case key
            when :style
              result[:style] = value.to_sym
            when :currency
              result[:currency] = value.to_s
            when :currencyDisplay
              result[:currency_display] = value.to_sym
            when :minimumIntegerDigits
              result[:minimum_integer_digits] = Integer(value)
            when :minimumFractionDigits
              result[:minimum_fraction_digits] = Integer(value)
            when :maximumFractionDigits
              result[:maximum_fraction_digits] = Integer(value)
            when :minimumSignificantDigits
              result[:minimum_significant_digits] = Integer(value)
            when :maximumSignificantDigits
              result[:maximum_significant_digits] = Integer(value)
            when :useGrouping
              result[:use_grouping] = !!value
              # Unsupported options are silently ignored for now
              # TODO: Add support as icu4x gem adds features
            end
          end

          result
        end
      end

      # ICU4X DateTimeFormat implementation
      class DateTimeFormat
        # Initialize formatter with locale and options
        # @param locale [Locale::Tag::Simple] Locale for formatting
        # @param options [Hash] DateTimeFormat options
        def initialize(locale:, **options)
          @locale = convert_locale(locale)
          @options = convert_options(options)
          # ICU4X requires at least one of date_style or time_style
          # Default to :medium for both if neither specified
          @options[:date_style] ||= :medium unless @options[:time_style]
        end

        # Format datetime using ICU4X
        # @param value [Time, DateTime, Date] DateTime to format
        # @return [String] Formatted datetime
        def call(value) = ::ICU4X::DateTimeFormat.new(@locale, **@options).format(convert_to_time(value))

        # Convert Locale::Tag to ICU4X::Locale
        # @param locale [Locale::Tag::Simple, String] Locale to convert
        # @return [ICU4X::Locale] ICU4X locale object
        private def convert_locale(locale)
          locale_str = locale.respond_to?(:to_rfc) ? locale.to_rfc : locale.to_s
          ::ICU4X::Locale.parse(locale_str)
        end

        alias format call

        # Convert value to Time object
        # @param value [Time, DateTime, Date, String, Integer] Value to convert
        # @return [Time] Time object
        private def convert_to_time(value)
          case value
          when Time
            value
          when DateTime
            value.to_time
          when Date
            value.to_time
          when String
            Time.parse(value)
          when Integer
            Time.at(value)
          else
            raise ArgumentError, "Cannot convert #{value.class} to Time"
          end
        end

        # Convert FTL/JS style options to icu4x options
        # @param options [Hash] FTL/JS style options (camelCase)
        # @return [Hash] icu4x style options (snake_case with symbols)
        private def convert_options(options)
          result = {}

          options.each do |key, value|
            case key
            when :dateStyle
              result[:date_style] = value.to_sym
            when :timeStyle
              result[:time_style] = value.to_sym
            when :year
              result[:year] = value.to_sym
            when :month
              result[:month] = value.to_sym
            when :day
              result[:day] = value.to_sym
            when :weekday
              result[:weekday] = value.to_sym
            when :hour
              result[:hour] = value.to_sym
            when :minute
              result[:minute] = value.to_sym
            when :second
              result[:second] = value.to_sym
            when :timeZone
              result[:time_zone] = value.to_s
            when :hour12
              result[:hour12] = !!value
              # Unsupported options are silently ignored for now
              # TODO: Add support as icu4x gem adds features
            end
          end

          result
        end
      end
    end
  end
end
