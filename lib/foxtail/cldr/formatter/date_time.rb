# frozen_string_literal: true

require "date"
require "locale"
require "strscan"
require "time"
require "tzinfo"

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
            @timezone_names = Foxtail::CLDR::Repository::TimezoneNames.new(locale)

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
            # If no timezone specified, use system timezone (Node.js compatibility)
            timezone_option = system_timezone unless timezone_option

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
              # Handle IANA timezone names using tzinfo
              apply_named_timezone(utc_time, timezone_string)
            end
          end

          # Get system timezone ID (e.g., "Asia/Tokyo", "America/New_York")
          private def system_timezone
            @system_timezone ||= Foxtail::CLDR::Formatter::LocalTimezoneDetector.detect.id
          end

          # Format GMT-style offset name for timezone display (e.g., "GMT+9", "GMT-5")
          private def format_gmt_offset_name(offset_string)
            # Parse offset string like "+09:00" or "-05:00"
            match = offset_string.match(/^([+-])(\d{2}):(\d{2})$/)
            return offset_string unless match

            sign = match[1]
            hours = match[2].to_i
            minutes = match[3].to_i

            # Format as "GMT+H" or "GMT-H" (Node.js style, no leading zeros for hours)
            if minutes.zero?
              "GMT#{sign}#{hours}"
            else
              # Include minutes if non-zero (rare case)
              "GMT#{sign}#{hours}:#{sprintf('%02d', minutes)}"
            end
          end

          # Get metazone ID for timezone ID
          private def timezone_to_metazone(timezone_id)
            @metazone_mapping ||= load_metazone_mapping
            @metazone_mapping[timezone_id]
          end

          # Load metazone mapping data
          private def load_metazone_mapping
            mapping_file = File.join(__dir__, "..", "..", "..", "..", "data", "cldr", "metazone_mapping.yml")

            return {} unless File.exist?(mapping_file)

            begin
              require "yaml"
              yaml_data = YAML.load_file(mapping_file)
              # Handle both string and symbol keys
              yaml_data[:timezone_to_metazone] || yaml_data["timezone_to_metazone"] || {}
            rescue => e
              {}
            end
          end

          # Apply named timezone using tzinfo (e.g., "America/New_York", "Asia/Tokyo")
          private def apply_named_timezone(utc_time, timezone_name)
            timezone = TZInfo::Timezone.get(timezone_name)
            # Convert UTC time to the specified timezone
            timezone.utc_to_local(utc_time)
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
              "a" => @time_with_zone.strftime("%p"),
              # Timezone symbols
              "zzzz" => format_timezone_name(:long),
              "z" => format_timezone_name(:short),
              "VVV" => format_timezone_exemplar_city,
              "VV" => format_timezone_id,
              "ZZZZZ" => format_timezone_offset_iso,
              "Z" => format_timezone_offset_basic
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

          # Format timezone name (z, zzzz)
          private def format_timezone_name(length)
            # Get the effective timezone ID (original option or system timezone)
            timezone_id = @options[:timeZone] || system_timezone

            # Try to get localized timezone name from CLDR data
            name = @timezone_names.zone_name(timezone_id, length, :generic) ||
                   @timezone_names.zone_name(timezone_id, length, :standard)

            # If no zone-specific name, try metazone mapping
            if name.nil?
              metazone_id = timezone_to_metazone(timezone_id)
              if metazone_id
                name = @timezone_names.metazone_name(metazone_id, length, :standard) ||
                       @timezone_names.metazone_name(metazone_id, length, :generic)
              end
            end

            # If no localized name found and this is an offset format, generate GMT-style name
            if name.nil? && timezone_id.match?(/^[+-]\d{2}:\d{2}$/)
              name = format_gmt_offset_name(timezone_id)
            end

            # Fall back to timezone ID if no name available
            name || timezone_id
          end

          # Format exemplar city (VVV)
          private def format_timezone_exemplar_city
            # Get the effective timezone ID (original option or system timezone)
            timezone_id = @options[:timeZone] || system_timezone

            # Get exemplar city or extract from timezone ID
            city = @timezone_names.exemplar_city(timezone_id)
            city || extract_city_from_timezone_id(timezone_id)
          end

          # Format timezone ID (VV)
          private def format_timezone_id
            @options[:timeZone] || system_timezone
          end

          # Format timezone offset in ISO format (ZZZZZ: +09:00, -05:00)
          private def format_timezone_offset_iso
            return nil unless @time_with_zone && @options[:timeZone]

            # Calculate offset from timezone setting
            offset_seconds = calculate_timezone_offset
            @timezone_names.format_offset(offset_seconds)
          end

          # Format timezone offset in basic format (Z: +0900, -0500)
          private def format_timezone_offset_basic
            return nil unless @time_with_zone && @options[:timeZone]

            # Calculate offset from timezone setting
            offset_seconds = calculate_timezone_offset
            hours = offset_seconds.abs / 3600
            minutes = (offset_seconds.abs % 3600) / 60
            sign = offset_seconds >= 0 ? "+" : "-"
            "%s%02d%02d" % [sign, hours, minutes]
          end

          # Calculate timezone offset in seconds from UTC
          private def calculate_timezone_offset
            return 0 unless @original_time && @time_with_zone

            # If timezone was applied, calculate the offset
            if @options[:timeZone]
              case @options[:timeZone]
              when "UTC", "GMT"
                0
              when /^[+-]\d{2}:\d{2}$/
                # Parse offset from format like "+09:00", "-05:00"
                match = @options[:timeZone].match(/^([+-])(\d{2}):(\d{2})$/)
                return 0 unless match

                sign = match[1] == "+" ? 1 : -1
                hours = Integer(match[2], 10)
                minutes = Integer(match[3], 10)
                sign * ((hours * 3600) + (minutes * 60))
              else
                # For named timezones, get offset from tzinfo
                begin
                  timezone = TZInfo::Timezone.get(@options[:timeZone])
                  utc_time = @original_time.getutc
                  period = timezone.period_for_utc(utc_time)
                  period.offset.utc_total_offset
                rescue TZInfo::InvalidTimezoneIdentifier
                  0
                end
              end
            else
              0
            end
          end

          # Extract city name from timezone ID (e.g., "America/New_York" -> "New York")
          private def extract_city_from_timezone_id(timezone_id)
            parts = timezone_id.split("/")
            return timezone_id if parts.length < 2

            city = parts.last
            # Replace underscores with spaces and capitalize words
            city.tr("_", " ").split.map(&:capitalize).join(" ")
          end
        end
      end
    end
  end
end
