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

            # Parse and convert value to Time for consistent processing
            @time = convert_to_time(value)
          end

          # Format the date/time value using CLDR data and options
          def format
            return @original_value.to_s if @time.nil?

            # Handle custom pattern first (highest priority)
            if @options[:pattern]
              format_with_pattern(@options[:pattern])
            elsif @options[:dateStyle] || @options[:timeStyle]
              # Handle dateStyle/timeStyle (Intl.DateTimeFormat style)
              format_with_styles
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

          private def format_with_styles
            date_style = @options[:dateStyle]
            time_style = @options[:timeStyle]

            if date_style && time_style
              # Both date and time
              date_pattern = @formats.date_pattern(date_style)
              time_pattern = @formats.time_pattern(time_style)
              pattern = "#{date_pattern} #{time_pattern}"
            elsif date_style
              # Date only
              pattern = @formats.date_pattern(date_style)
            elsif time_style
              # Time only
              pattern = @formats.time_pattern(time_style)
            else
              # Fallback
              pattern = @formats.datetime_pattern("medium", "medium")
            end

            format_with_pattern(pattern)
          end

          private def format_with_fields
            if @options.empty?
              # Default format
              return format_with_styles
            end

            parts = []

            # Weekday
            if @options[:weekday]
              width = case @options[:weekday]
                      when "long" then "wide"
                      when "short" then "abbreviated"
                      when "narrow" then "narrow"
                      else "wide"
                      end
              weekday_key = %w[sun mon tue wed thu fri sat][@time.wday]
              parts << @formats.weekday_name(weekday_key, width)
            end

            # Year
            if @options[:year]
              case @options[:year]
              when "numeric"
                parts << @time.strftime("%Y")
              when "2-digit"
                parts << @time.strftime("%y")
              end
            end

            # Month
            if @options[:month]
              case @options[:month]
              when "numeric"
                parts << @time.month.to_s
              when "2-digit"
                parts << @time.strftime("%m")
              when "long"
                parts << @formats.month_name(@time.month, "wide")
              when "short"
                parts << @formats.month_name(@time.month, "abbreviated")
              when "narrow"
                parts << @formats.month_name(@time.month, "narrow")
              end
            end

            # Day
            if @options[:day]
              case @options[:day]
              when "numeric"
                parts << @time.day.to_s
              when "2-digit"
                parts << @time.strftime("%d")
              end
            end

            # Hour, minute, second (basic implementation)
            if @options[:hour]
              parts << @time.strftime(@options[:hour12] ? "%l" : "%H").strip
            end

            if @options[:minute]
              parts << @time.strftime("%M")
            end

            if @options[:second]
              parts << @time.strftime("%S")
            end

            parts.join(" ")
          end

          # Format time using a CLDR pattern with formal parser
          private def format_with_pattern(pattern)
            weekday_key = %w[sun mon tue wed thu fri sat][@time.wday]

            # Use the formal CLDR pattern parser
            parser = Foxtail::CLDR::PatternParser::DateTime.new
            tokens = parser.parse(pattern)

            # Define replacements for each field token
            replacements = {
              "EEEE" => @formats.weekday_name(weekday_key, "wide"),
              "EEE" => @formats.weekday_name(weekday_key, "abbreviated"),
              "MMMM" => @formats.month_name(@time.month, "wide"),
              "MMM" => @formats.month_name(@time.month, "abbreviated"),
              "MM" => @time.strftime("%m"),
              "M" => @time.month.to_s,
              "yyyy" => @time.year.to_s,
              "yy" => @time.strftime("%y"),
              "y" => @time.year.to_s,
              "dd" => @time.strftime("%d"),
              "d" => @time.day.to_s,
              "HH" => @time.strftime("%H"),
              "H" => @time.hour.to_s,
              "hh" => @time.strftime("%I"),
              "h" => @time.strftime("%-l"),
              "mm" => @time.strftime("%M"),
              "ss" => @time.strftime("%S"),
              "a" => @time.strftime("%p")
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
