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
            timezone_option ||= system_timezone

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
            hours = Integer(match[2], 10)
            minutes = Integer(match[3], 10)

            # Format as "GMT+H" or "GMT-H" (Node.js style, no leading zeros for hours)
            if minutes.zero?
              "GMT#{sign}#{hours}"
            else
              # Include minutes if non-zero (rare case)
              "GMT#{sign}#{hours}:#{"%02d" % minutes}"
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
            rescue
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
              # Both date and time - use CLDR datetime combination pattern
              @formats.datetime_pattern(date_style, time_style)
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

          # Generate CLDR pattern key from field options
          private def generate_available_format_key(options)
            key_parts = []

            # Order following CLDR availableFormats convention: y, MMM, E, d
            # Year (y)
            if options[:year]
              key_parts << "y"
            end

            # Month (M)
            if options[:month]
              key_parts << case options[:month]
                           when "long"
                             "MMMM"  # Full month name pattern
                           when "short"
                             "MMM"   # Abbreviated month name pattern
                           when "numeric"
                             "M"
                           when "2-digit"
                             "MM"
                           else
                             "MMM"
                           end
            end

            # Weekday (E) - comes before day in some patterns
            if options[:weekday]
              key_parts << case options[:weekday]
                           when "long"
                             "EEEE"  # Full weekday name
                           when "short"
                             "EEE"   # Abbreviated weekday name
                           when "narrow"
                             "E"     # Single letter weekday
                           else
                             "E"     # Default to single letter
                           end
            end

            # Day (d) - comes last
            if options[:day]
              key_parts << case options[:day]
                           when "numeric"
                             "d"
                           when "2-digit"
                             "dd"
                           else
                             "d"
                           end
            end

            key_parts.join
          end

          private def format_with_fields
            # Try to find appropriate CLDR availableFormats pattern
            pattern_key = generate_available_format_key(@options)
            available_pattern = @formats.available_format(pattern_key)

            # If exact pattern not found, try fallback patterns
            if !available_pattern && @options[:month] == "long"
              # Try with MMM instead of MMMM for month long
              fallback_key = pattern_key.gsub("MMMM", "MMM")
              available_pattern = @formats.available_format(fallback_key)

              if available_pattern
                # Upgrade MMM to MMMM in the pattern for long month names
                available_pattern = available_pattern.gsub("MMM", "MMMM")
              end
            end

            if available_pattern && only_date_fields?
              # Use CLDR availableFormats pattern for proper ordering and separators
              format_with_pattern(available_pattern)
            else
              # Fallback to individual field formatting for time fields or unavailable patterns
              format_fields_individually
            end
          end

          # Check if options contain only date fields (no time fields)
          private def only_date_fields?
            time_fields = %i[hour minute second hour12]
            time_fields.none? {|field| @options.key?(field) }
          end

          # Format time fields using CLDR time patterns
          private def format_time_fields
            # Check if we have any time fields to format
            return nil unless @options[:hour] || @options[:minute] || @options[:second]

            # Generate time pattern key based on field options
            time_pattern_key = generate_time_pattern_key

            # Try to get CLDR availableFormats time pattern
            available_pattern = @formats.available_format(time_pattern_key)

            if available_pattern
              # Use CLDR available format pattern
              format_with_pattern(available_pattern)
            else
              # Fallback to basic time formatting with locale-appropriate separators
              format_time_with_basic_pattern
            end
          end

          # Generate time pattern key (e.g., "Hms", "hms", "Hm", "hm")
          private def generate_time_pattern_key
            key_parts = []

            # Hour pattern
            if @options[:hour]
              key_parts << if @options[:hour12]
                             "h" # 12-hour format
                           else
                             "H" # 24-hour format
                           end
            end

            # Minute pattern
            if @options[:minute]
              key_parts << "m"
            end

            # Second pattern
            if @options[:second]
              key_parts << "s"
            end

            key_parts.join
          end

          # Format time with basic pattern using locale's time format as template
          private def format_time_with_basic_pattern
            # Find the best matching time template
            template_pattern = find_best_time_template

            # Parse the template pattern into tokens
            parser = Foxtail::CLDR::PatternParser::DateTime.new
            template_tokens = parser.parse(template_pattern)

            # Build new pattern by filtering and adapting tokens based on requested fields
            adapted_tokens = adapt_time_tokens_to_fields(template_tokens)

            # Reconstruct pattern and format
            adapted_pattern = adapted_tokens.map(&:value).join
            format_with_pattern(adapted_pattern)
          end

          # Find the best time template that matches our field requirements
          private def find_best_time_template
            # Try to find a template that matches our field count
            field_count = [@options[:hour], @options[:minute], @options[:second]].count {|f| f }

            case field_count
            when 3
              # Hour, minute, second - try full or medium first
              @formats.time_pattern("full") || @formats.time_pattern("medium")
            when 2
              # Hour, minute - try short
              @formats.time_pattern("short")
            else
              @formats.time_pattern("short")
            end
          end

          # Adapt template tokens to match requested fields
          private def adapt_time_tokens_to_fields(template_tokens)
            adapted_tokens = []

            template_tokens.each do |token|
              case token
              when Foxtail::CLDR::PatternParser::DateTime::FieldToken
                # Handle field tokens based on requested options
                adapted_token = adapt_field_token(token)
                adapted_tokens << adapted_token if adapted_token
              when Foxtail::CLDR::PatternParser::DateTime::LiteralToken
                # Include literal tokens (separators, units) as-is for now
                # Will be filtered later based on adjacent field presence
                adapted_tokens << token
              when Foxtail::CLDR::PatternParser::DateTime::QuotedToken
                # Include quoted literals as-is
                adapted_tokens << token
              else
                adapted_tokens << token
              end
            end

            # Remove orphaned separators (literals between missing fields)
            filter_orphaned_literals(adapted_tokens)
          end

          # Adapt individual field token based on requested options
          private def adapt_field_token(token)
            field_type = detect_field_type(token.value)

            case field_type
            when :hour
              return nil unless @options[:hour]

              adapt_hour_token(token)
            when :minute
              return nil unless @options[:minute]

              adapt_minute_token(token)
            when :second
              return nil unless @options[:second]

              adapt_second_token(token)
            when :am_pm
              return nil unless @options[:hour12]

              token # Keep AM/PM as-is
            else
              # Unknown field type - keep as-is
              token
            end
          end

          # Detect field type from token value
          private def detect_field_type(token_value)
            case token_value
            when /^H+$/, /^h+$/, /^K+$/, /^k+$/
              :hour
            when /^m+$/
              :minute
            when /^s+$/
              :second
            when /^a+$/, /^b+$/, /^B+$/
              :am_pm
            else
              :unknown
            end
          end

          # Adapt hour token based on options
          private def adapt_hour_token(_token)
            pattern = if @options[:hour12]
                        # Use 12-hour format
                        @options[:hour] == "2-digit" ? "hh" : "h"
                      else
                        # Use 24-hour format
                        @options[:hour] == "2-digit" ? "HH" : "H"
                      end
            Foxtail::CLDR::PatternParser::DateTime::FieldToken.new(pattern)
          end

          # Adapt minute token based on options
          private def adapt_minute_token(_token)
            # Always use 2-digit minutes for consistency
            Foxtail::CLDR::PatternParser::DateTime::FieldToken.new("mm")
          end

          # Adapt second token based on options
          private def adapt_second_token(_token)
            # Always use 2-digit seconds for consistency
            Foxtail::CLDR::PatternParser::DateTime::FieldToken.new("ss")
          end

          # Remove orphaned literal tokens between missing fields
          private def filter_orphaned_literals(tokens)
            result = []
            i = 0

            while i < tokens.length
              token = tokens[i]

              case token
              when Foxtail::CLDR::PatternParser::DateTime::LiteralToken
                # Check if this literal is between two field tokens
                prev_is_field = i > 0 && tokens[i - 1].is_a?(Foxtail::CLDR::PatternParser::DateTime::FieldToken)
                next_is_field = i < tokens.length - 1 && tokens[i + 1].is_a?(Foxtail::CLDR::PatternParser::DateTime::FieldToken)

                # Include literal only if it's between fields or at boundaries with fields
                if (prev_is_field && next_is_field) ||
                   (i == 0 && next_is_field) ||
                   (i == tokens.length - 1 && prev_is_field)

                  result << token
                end
                # Otherwise skip orphaned literals
              else
                result << token
              end

              i += 1
            end

            result
          end

          # Extract time separator from CLDR time format template
          private def extract_time_separator_from_template(template)
            # Parse template using CLDR parser to find actual separators
            parser = Foxtail::CLDR::PatternParser::DateTime.new
            tokens = parser.parse(template)

            # Find the first literal token between time fields
            prev_was_time_field = false
            time_field_types = %i[hour minute second].freeze

            tokens.each do |token|
              case token
              when Foxtail::CLDR::PatternParser::DateTime::FieldToken
                field_type = detect_field_type(token.value)
                prev_was_time_field = time_field_types.include?(field_type)
              when Foxtail::CLDR::PatternParser::DateTime::LiteralToken
                # Return the first separator found between time fields
                return token.value if prev_was_time_field
              end
            end

            # Default to colon if no separator found
            ":"
          end

          # Format individual fields with basic ordering
          private def format_fields_individually
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

            # Format time fields using appropriate CLDR pattern
            time_part = format_time_fields
            parts << time_part if time_part && !time_part.empty?

            parts.reject(&:empty?).join(" ")
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
              "E" => @formats.weekday_name(weekday_key, "abbreviated"),
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
