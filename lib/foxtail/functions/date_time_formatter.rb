# frozen_string_literal: true

require "date"
require "locale"
require "strscan"
require "time"
require_relative "../cldr/date_time_pattern_parser"

module Foxtail
  module Functions
    # CLDR-based date and time formatter implementing Intl.DateTimeFormat functionality
    class DateTimeFormatter
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
        # Locale is now guaranteed to be a Locale instance from Bundle/Resolver

        # Get the first positional argument (the value to format)
        value = args.first
        # Handle different input types
        date_obj =
          case value
          when Date, Time, DateTime
            value
          when String
            # Try to parse as timestamp first, then as date string
            # Check if it's a numeric string (Unix timestamp)
            # Note: May raise ArgumentError for invalid date/time strings
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
          else
            return value.to_s
          end

        # Convert to Time for consistent processing
        time_obj = date_obj.is_a?(Time) ? date_obj : Time.parse(date_obj.to_s)

        # Load CLDR formatting data
        formats = Foxtail::CLDR::DateTimeFormats.new(locale)

        # Check if CLDR data is actually available for this locale
        unless formats.data?
          raise Foxtail::CLDR::DataNotAvailable, "CLDR data not available for locale: #{locale}"
        end

        # Handle custom pattern first (highest priority)
        if options[:pattern]
          format_with_pattern(time_obj, formats, options[:pattern])
        elsif options[:dateStyle] || options[:timeStyle]
          # Handle dateStyle/timeStyle (Intl.DateTimeFormat style)
          format_with_styles(time_obj, formats, options)
        else
          # Handle individual field specifications
          format_with_fields(time_obj, formats, options)
        end
      end

      private def format_with_styles(time_obj, formats, options)
        date_style = options[:dateStyle]
        time_style = options[:timeStyle]

        if date_style && time_style
          # Both date and time
          date_pattern = formats.date_pattern(date_style)
          time_pattern = formats.time_pattern(time_style)
          pattern = "#{date_pattern} #{time_pattern}"
        elsif date_style
          # Date only
          pattern = formats.date_pattern(date_style)
        elsif time_style
          # Time only
          pattern = formats.time_pattern(time_style)
        else
          # Fallback
          pattern = formats.datetime_pattern("medium", "medium")
        end

        format_with_pattern(time_obj, formats, pattern)
      end

      private def format_with_fields(time_obj, formats, options)
        if options.empty?
          # Default format
          return format_with_styles(time_obj, formats, {"dateStyle" => "medium", "timeStyle" => "medium"})
        end

        parts = []

        # Weekday
        if options[:weekday]
          width = case options[:weekday]
                  when "long" then "wide"
                  when "short" then "abbreviated"
                  when "narrow" then "narrow"
                  else "wide"
                  end
          weekday_key = %w[sun mon tue wed thu fri sat][time_obj.wday]
          parts << formats.weekday_name(weekday_key, width)
        end

        # Year
        if options[:year]
          case options[:year]
          when "numeric"
            parts << time_obj.strftime("%Y")
          when "2-digit"
            parts << time_obj.strftime("%y")
          end
        end

        # Month
        if options[:month]
          case options[:month]
          when "numeric"
            parts << time_obj.month.to_s
          when "2-digit"
            parts << time_obj.strftime("%m")
          when "long"
            parts << formats.month_name(time_obj.month, "wide")
          when "short"
            parts << formats.month_name(time_obj.month, "abbreviated")
          when "narrow"
            parts << formats.month_name(time_obj.month, "narrow")
          end
        end

        # Day
        if options[:day]
          case options[:day]
          when "numeric"
            parts << time_obj.day.to_s
          when "2-digit"
            parts << time_obj.strftime("%d")
          end
        end

        # Hour, minute, second (basic implementation)
        if options[:hour]
          parts << time_obj.strftime(options[:hour12] ? "%l" : "%H").strip
        end

        if options[:minute]
          parts << time_obj.strftime("%M")
        end

        if options[:second]
          parts << time_obj.strftime("%S")
        end

        parts.join(" ")
      end

      # Format time using a CLDR pattern with formal parser
      private def format_with_pattern(time_obj, formats, pattern)
        weekday_key = %w[sun mon tue wed thu fri sat][time_obj.wday]

        # Use the formal CLDR pattern parser
        parser = Foxtail::CLDR::DateTimePatternParser.new
        tokens = parser.parse(pattern)

        # Define replacements for each field token
        replacements = {
          "EEEE" => formats.weekday_name(weekday_key, "wide"),
          "EEE" => formats.weekday_name(weekday_key, "abbreviated"),
          "MMMM" => formats.month_name(time_obj.month, "wide"),
          "MMM" => formats.month_name(time_obj.month, "abbreviated"),
          "MM" => time_obj.strftime("%m"),
          "M" => time_obj.month.to_s,
          "yyyy" => time_obj.year.to_s,
          "yy" => time_obj.strftime("%y"),
          "y" => time_obj.year.to_s,
          "dd" => time_obj.strftime("%d"),
          "d" => time_obj.day.to_s,
          "HH" => time_obj.strftime("%H"),
          "H" => time_obj.hour.to_s,
          "hh" => time_obj.strftime("%I"),
          "h" => time_obj.strftime("%-l"),
          "mm" => time_obj.strftime("%M"),
          "ss" => time_obj.strftime("%S"),
          "a" => time_obj.strftime("%p")
        }

        # Format each token according to its type
        tokens.map {|token|
          case token
          when Foxtail::CLDR::DateTimePatternParser::FieldToken
            replacements[token.value] || token.value
          when Foxtail::CLDR::DateTimePatternParser::LiteralToken
            token.value
          when Foxtail::CLDR::DateTimePatternParser::QuotedToken
            token.literal_text
          else
            token.value
          end
        }.join
      end
    end
  end
end
