# frozen_string_literal: true

require "execjs"
require "json"

module Foxtail
  module Function
    # JavaScript-based formatters using ExecJS and Node.js Intl APIs
    module JavaScript
      # Base class for JavaScript formatters
      class Base
        def initialize
          @context = nil
          @runtime_name = nil
        end

        private def ensure_context!
          return if @context

          @context = build_context
          @runtime_name = ExecJS.runtime.name
        rescue => e
          raise RuntimeError, "JavaScript runtime not available: #{e.message}"
        end

        private def build_context
          ExecJS.compile(javascript_code)
        end
      end

      # JavaScript NumberFormat implementation
      class NumberFormat < Base
        # Initialize formatter with locale and options
        # @param locale [Locale::Tag::Simple] Locale for formatting
        # @param options [Hash] Formatting options
        def initialize(locale:, **options)
          super()
          @locale = locale
          @options = options
        end

        # Format number using JavaScript Intl.NumberFormat
        # @param value [Numeric] Number to format
        # @return [String] Formatted number
        def call(value)
          ensure_context!
          js_options = convert_number_options(@options)
          result = @context.call("formatNumber", value, @locale.to_rfc, js_options)
          result.to_s
        rescue => e
          raise ArgumentError, "Number formatting failed: #{e.message}"
        end

        alias format call

        private def javascript_code
          <<~JS
            function formatNumber(value, locale, options) {
              if (value === null || value === undefined) {
                return String(value);
              }

              if (typeof value === 'string') {
                const numValue = parseFloat(value);
                if (isNaN(numValue)) {
                  return String(value);
                }
                value = numValue;
              }

              return new Intl.NumberFormat(locale, options || {}).format(value);
            }
          JS
        end

        private def convert_number_options(options)
          js_options = {}

          options.each do |key, value|
            case key
            when :style
              js_options["style"] = value.to_s
            when :currency
              js_options["currency"] = value.to_s
            when :currencyDisplay
              js_options["currencyDisplay"] = value.to_s
            when :currencySign
              js_options["currencySign"] = value.to_s
            when :unit
              js_options["unit"] = value.to_s
            when :unitDisplay
              js_options["unitDisplay"] = value.to_s
            when :notation
              js_options["notation"] = value.to_s
            when :compactDisplay
              js_options["compactDisplay"] = value.to_s
            when :useGrouping
              js_options["useGrouping"] = !value.nil?
            when :minimumIntegerDigits, :minimumFractionDigits, :maximumFractionDigits,
                 :minimumSignificantDigits, :maximumSignificantDigits

              js_options[key.to_s] = Integer(value)
            when :roundingMode
              js_options["roundingMode"] = value.to_s
            when :roundingPriority
              js_options["roundingPriority"] = value.to_s
            when :roundingIncrement
              js_options["roundingIncrement"] = Integer(value)
            when :trailingZeroDisplay
              js_options["trailingZeroDisplay"] = value.to_s
            else
              raise ArgumentError, "Unknown number option: #{key}"
            end
          end

          js_options
        end
      end

      # JavaScript DateTimeFormat implementation
      class DateTimeFormat < Base
        # Initialize formatter with locale and options
        # @param locale [Locale::Tag::Simple] Locale for formatting
        # @param options [Hash] DateTimeFormat options
        def initialize(locale:, **options)
          super()
          @locale = locale
          @options = options
        end

        # Format datetime using JavaScript Intl.DateTimeFormat
        # @param value [Time, DateTime, Date, String, Integer] DateTime to format
        # @return [String] Formatted datetime
        def call(value)
          ensure_context!
          timestamp = convert_to_timestamp(value)
          js_options = convert_datetime_options(@options)
          result = @context.call("formatDateTime", timestamp, @locale.to_rfc, js_options)
          result.to_s
        rescue => e
          raise ArgumentError, "DateTime formatting failed: #{e.message}"
        end

        alias format call

        private def javascript_code
          <<~JS
            function formatDateTime(timestamp, locale, options) {
              if (timestamp === null || timestamp === undefined) {
                return String(timestamp);
              }

              const date = new Date(timestamp);

              if (isNaN(date.getTime())) {
                return String(timestamp);
              }

              return new Intl.DateTimeFormat(locale, options || {}).format(date);
            }
          JS
        end

        private def convert_to_timestamp(value)
          case value
          when Time
            # High precision: epoch seconds * 1000 + nanoseconds / 1,000,000
            (value.tv_sec * 1000) + (value.tv_nsec / 1_000_000)
          when DateTime
            time = value.to_time
            (time.tv_sec * 1000) + (time.tv_nsec / 1_000_000)
          when Date
            # Date only: treat as 00:00:00 in local time
            value.to_time.tv_sec * 1000
          when Numeric
            # Assume already timestamp (seconds or milliseconds)
            Integer(value)
          when String
            time = Time.parse(value)
            (time.tv_sec * 1000) + (time.tv_nsec / 1_000_000)
          else
            raise ArgumentError, "Cannot convert #{value.class} to timestamp"
          end
        rescue ArgumentError
          raise
        rescue => e
          raise ArgumentError, "Invalid time value: #{value.inspect} (#{e.message})"
        end

        private def convert_datetime_options(options)
          js_options = {}

          options.each do |key, value|
            case key
            when :hour12
              js_options["hour12"] = !value.nil?
            when :fractionalSecondDigits
              js_options["fractionalSecondDigits"] = Integer(value)
            when :dateStyle, :timeStyle, :calendar, :dayPeriod, :numberingSystem,
                 :localeMatcher, :timeZone, :hourCycle, :formatMatcher,
                 :weekday, :era, :year, :month, :day, :hour, :minute, :second, :timeZoneName

              js_options[key.to_s] = value.to_s
            else
              raise ArgumentError, "Unknown datetime option: #{key}"
            end
          end

          js_options
        end
      end
    end
  end
end
