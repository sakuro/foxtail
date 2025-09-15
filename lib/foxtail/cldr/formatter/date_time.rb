# frozen_string_literal: true

require "date"
require "locale"
require "strscan"
require "time"

module Foxtail
  module CLDR
    module Formatter
      # CLDR-based date and time formatter implementing Intl.DateTimeFormat functionality
      class DateTime
        # Format dates with locale-specific formatting using CLDR data
        # Intl.DateTimeFormat equivalent with CLDR integration
        #
        # Options:
        #   dateStyle: "full", "long", "medium", "short"
        #   timeStyle: "full", "long", "medium", "short"
        #   year: "numeric", "2-digit"
        #   month: "numeric", "2-digit", "long", "short"
        #   day: "numeric", "2-digit"
        #   weekday: "long", "short", "narrow"
        #   locale: Locale instance (required)
        #
        # @raise [ArgumentError] when the value cannot be parsed as a date/time
        # @raise [Foxtail::CLDR::DataNotAvailable] when CLDR data is not available for the locale
        def call(*args, locale:, **options)
          context = Context.new(args.first, locale, options)
          context.format
        end

        # Context object for date/time formatting operations
        class Context
          def initialize(value, locale, options)
            # Keep original value for fallback when conversion fails
            @original_value = value
            @options = options.dup.freeze
            @formats = Foxtail::CLDR::Repository::DateTimeFormats.new(locale)

            # Parse and convert value to Time
            @original_time = convert_to_time(value)
            # Apply timezone conversion once during initialization
            utc_time = @original_time&.getutc
            @time_with_zone = apply_timezone(utc_time, options[:timeZone])
          end

          # Format the date/time value using CLDR data and options
          def format
            return @original_value.to_s if @time_with_zone.nil?

            # Handle custom pattern first (highest priority)
            if @options[:pattern]
              format_with_pattern(@options[:pattern])
            elsif @options[:dateStyle] || @options[:timeStyle] || !field_options?
              # Handle dateStyle/timeStyle or default format (no fields = medium/medium)
              pattern = build_pattern_from_styles
              format_with_pattern(pattern)
            else
              # Handle individual field specifications
              format_with_fields
            end
          end

          # Convert value to Time for consistent processing
          private def convert_to_time(value)
            case value
            when Time
              value
            when Date, DateTime
              value.to_time
            when String
              # Try to parse as timestamp first, then as date string
              # Check if it's a numeric string (Unix timestamp)
              if value.match?(/^\d+\.?\d*$/)
                timestamp = Float(value)
                timestamp /= 1000.0 if timestamp > 1_000_000_000_000
                Time.at(timestamp)
              else
                Time.parse(value)
              end
            when Numeric
              # Assume Unix timestamp (milliseconds or seconds)
              timestamp = value > 1_000_000_000_000 ? value / 1000.0 : value
              Time.at(timestamp)
            end
          end

          # Apply timezone conversion to UTC time for display
          private def apply_timezone(utc_time, timezone_option)
            # If no timezone specified, use original time (preserve local timezone)
            return @original_time unless timezone_option

            case timezone_option
            when "UTC", "GMT"
              utc_time
            when String
              # Handle timezone names like "America/New_York", "+09:00", etc.
              apply_timezone_string(utc_time, timezone_option)
            else
              # Default to original time if timezone option is invalid
              @original_time
            end
          end

          # Apply timezone specified as string
          private def apply_timezone_string(utc_time, timezone_string)
            # Handle offset formats like "+09:00", "-05:00"
            if timezone_string.match?(/^[+-]\d{2}:\d{2}$/)
              apply_offset_timezone(utc_time, timezone_string)
            else
              # For named timezones, we'll need proper timezone database support
              # For now, return UTC as fallback
              utc_time
            end
          end

          # Apply offset-based timezone (e.g., "+09:00", "-05:00")
          private def apply_offset_timezone(utc_time, offset_string)
            # Parse offset string like "+09:00" or "-05:00"
            match = offset_string.match(/^([+-])(\d{2}):(\d{2})$/)
            return utc_time unless match

            sign = match[1] == "+" ? 1 : -1
            hours = Integer(match[2], 10)
            minutes = Integer(match[3], 10)
            offset_seconds = sign * ((hours * 3600) + (minutes * 60))

            # Apply offset to UTC time
            utc_time + offset_seconds
          end

          # Check if individual field options are specified
          private def field_options?
            field_keys = %i[year month day weekday hour minute second hour12]
            field_keys.any? {|key| @options.key?(key) }
          end

          # Build CLDR pattern from dateStyle/timeStyle options
          private def build_pattern_from_styles
            date_style = @options[:dateStyle]
            time_style = @options[:timeStyle]

            if date_style && time_style
              # Both date and time
              date_pattern = @formats.date_pattern(date_style)
              time_pattern = @formats.time_pattern(time_style)
              "#{date_pattern} #{time_pattern}"
            elsif date_style
              # Date only
              @formats.date_pattern(date_style)
            elsif time_style
              # Time only
              @formats.time_pattern(time_style)
            else
              # Fallback
              @formats.datetime_pattern("medium", "medium")
            end
          end

          private def format_with_fields
            parts = []

            # Weekday
            if @options[:weekday]
              width = case @options[:weekday]
                      when "long" then "wide"
                      when "short" then "abbreviated"
                      when "narrow" then "narrow"
                      else "wide"
                      end
              weekday_key = %w[sun mon tue wed thu fri sat][@time_with_zone.wday]
              parts << @formats.weekday_name(weekday_key, width)
            end

            # Year
            if @options[:year]
              case @options[:year]
              when "numeric"
                parts << @time_with_zone.strftime("%Y")
              when "2-digit"
                parts << @time_with_zone.strftime("%y")
              end
            end

            # Month
            if @options[:month]
              case @options[:month]
              when "numeric"
                parts << @time_with_zone.month.to_s
              when "2-digit"
                parts << @time_with_zone.strftime("%m")
              when "long"
                parts << @formats.month_name(@time_with_zone.month, "wide")
              when "short"
                parts << @formats.month_name(@time_with_zone.month, "abbreviated")
              when "narrow"
                parts << @formats.month_name(@time_with_zone.month, "narrow")
              end
            end

            # Day
            if @options[:day]
              case @options[:day]
              when "numeric"
                parts << @time_with_zone.day.to_s
              when "2-digit"
                parts << @time_with_zone.strftime("%d")
              end
            end

            # Hour, minute, second (basic implementation)
            if @options[:hour]
              parts << @time_with_zone.strftime(@options[:hour12] ? "%l" : "%H").strip
            end

            if @options[:minute]
              parts << @time_with_zone.strftime("%M")
            end

            if @options[:second]
              parts << @time_with_zone.strftime("%S")
            end

            parts.join(" ")
          end

          # Format time using a CLDR pattern with formal parser
          private def format_with_pattern(pattern)
            weekday_key = %w[sun mon tue wed thu fri sat][@time_with_zone.wday]

            # Use the formal CLDR pattern parser
            parser = Foxtail::CLDR::PatternParser::DateTime.new
            tokens = parser.parse(pattern)

            # Define replacements for each field token
            replacements = {
              "EEEE" => @formats.weekday_name(weekday_key, "wide"),
              "EEE" => @formats.weekday_name(weekday_key, "abbreviated"),
              "MMMM" => @formats.month_name(@time_with_zone.month, "wide"),
              "MMM" => @formats.month_name(@time_with_zone.month, "abbreviated"),
              "MM" => @time_with_zone.strftime("%m"),
              "M" => @time_with_zone.month.to_s,
              "yyyy" => @time_with_zone.year.to_s,
              "yy" => @time_with_zone.strftime("%y"),
              "y" => @time_with_zone.year.to_s,
              "dd" => @time_with_zone.strftime("%d"),
              "d" => @time_with_zone.day.to_s,
              "HH" => @time_with_zone.strftime("%H"),
              "H" => @time_with_zone.hour.to_s,
              "hh" => @time_with_zone.strftime("%I"),
              "h" => @time_with_zone.strftime("%-l"),
              "mm" => @time_with_zone.strftime("%M"),
              "ss" => @time_with_zone.strftime("%S"),
              "a" => @time_with_zone.strftime("%p")
            }

            # Format each token according to its type
            tokens.map {|token|
              case token
              when Foxtail::CLDR::PatternParser::DateTime::FieldToken
                replacements[token.value] || token.value
              when Foxtail::CLDR::PatternParser::DateTime::LiteralToken
                token.value
              when Foxtail::CLDR::PatternParser::DateTime::QuotedToken
                token.literal_text
              else
                token.value
              end
            }.join
          end
        end
      end
    end
  end
end
