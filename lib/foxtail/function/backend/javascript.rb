# frozen_string_literal: true

require "execjs"
require "json"

module Foxtail
  module Function
    module Backend
      # JavaScript backend using ExecJS
      # Delegates formatting to JavaScript's Intl.NumberFormat and Intl.DateTimeFormat
      class JavaScript < Base
        # Initialize JavaScript backend
        def initialize
          super
          @context = nil
          @runtime_name = nil
        end

        # Execute FTL function using JavaScript Intl APIs
        # @param function_name [String] "NUMBER" or "DATETIME"
        # @param value [Object] Value to format
        # @param locale [Locale::Tag::Simple] Locale for formatting
        # @param options [Hash] Formatting options
        # @return [String] Formatted result
        # @raise [ArgumentError] For unknown functions or invalid values
        def call(function_name, value, locale:, **)
          ensure_context!

          case function_name.to_s.upcase
          when "NUMBER"
            format_number(value, locale:, **)
          when "DATETIME"
            format_datetime(value, locale:, **)
          else
            raise ArgumentError, "Unknown function: #{function_name}"
          end
        end

        # Check if JavaScript runtime is available
        # @return [Boolean] True if ExecJS runtime is available
        def available?
          ensure_context!
          !@context.nil?
        rescue
          false
        end

        # Get backend name with runtime information
        # @return [String] Backend name including JavaScript runtime
        def name
          if available?
            "JavaScript (#{@runtime_name})"
          else
            "JavaScript (unavailable)"
          end
        end

        private def format_number(value, locale:, **options)
          js_options = convert_number_options(options)
          result = @context.call("formatNumber", value, locale.to_rfc, js_options)
          result.to_s
        rescue => e
          raise ArgumentError, "Number formatting failed: #{e.message}"
        end

        # Format datetime using JavaScript Intl.DateTimeFormat
        # @param value [Time, DateTime, Date, String, Integer] DateTime to format
        # @param locale [Locale::Tag::Simple] Locale for formatting
        # @param options [Hash] DateTimeFormat options
        # @return [String] Formatted datetime
        private def format_datetime(value, locale:, **options)
          timestamp = convert_to_timestamp(value)
          js_options = convert_datetime_options(options)
          result = @context.call("formatDateTime", timestamp, locale.to_rfc, js_options)
          result.to_s
        rescue => e
          raise ArgumentError, "DateTime formatting failed: #{e.message}"
        end

        # Convert time value to JavaScript timestamp (milliseconds since epoch)
        # Uses high-precision integer arithmetic to avoid Float precision issues
        # @param value [Time, DateTime, Date, String, Integer] Time value to convert
        # @return [Integer] Milliseconds since Unix epoch
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

        # Convert Ruby number formatting options to JavaScript-compatible hash
        # @param options [Hash] Ruby options hash
        # @return [Hash] JavaScript-compatible options
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

        # Convert Ruby datetime formatting options to JavaScript-compatible hash
        # @param options [Hash] Ruby options hash
        # @return [Hash] JavaScript-compatible options
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

        # Ensure JavaScript context is initialized
        # @return [void]
        # @raise [RuntimeError] If JavaScript runtime is not available
        private def ensure_context!
          return if @context

          @context = build_context
          @runtime_name = ExecJS.runtime.name
        rescue => e
          raise RuntimeError, "JavaScript runtime not available: #{e.message}"
        end

        # Build ExecJS context with Intl polyfills
        # @return [ExecJS::Context] Compiled JavaScript context
        private def build_context
          ExecJS.compile(javascript_code)
        end

        # JavaScript code for number and datetime formatting
        # @return [String] JavaScript source code
        private def javascript_code
          <<~JS
            // Intl.NumberFormat wrapper with error handling
            function formatNumber(value, locale, options) {
              try {
                if (value === null || value === undefined) {
                  return String(value);
                }

                // Handle special numeric values
                if (typeof value === 'string') {
                  const numValue = parseFloat(value);
                  if (isNaN(numValue)) {
                    return String(value);
                  }
                  value = numValue;
                }

                return new Intl.NumberFormat(locale, options || {}).format(value);
              } catch (error) {
                // Fallback to basic string conversion
                return String(value);
              }
            }

            // Intl.DateTimeFormat wrapper with error handling
            function formatDateTime(timestamp, locale, options) {
              try {
                if (timestamp === null || timestamp === undefined) {
                  return String(timestamp);
                }

                // Create Date object from timestamp (milliseconds)
                const date = new Date(timestamp);

                // Check if date is valid
                if (isNaN(date.getTime())) {
                  return String(timestamp);
                }

                return new Intl.DateTimeFormat(locale, options || {}).format(date);
              } catch (error) {
                // Fallback to basic date string
                return new Date(timestamp).toString();
              }
            }

            // Test function to verify runtime capabilities
            function testIntlSupport() {
              try {
                new Intl.NumberFormat('en-US').format(1234);
                new Intl.DateTimeFormat('en-US').format(new Date());
                return true;
              } catch (error) {
                return false;
              }
            }
          JS
        end
      end
    end
  end
end
