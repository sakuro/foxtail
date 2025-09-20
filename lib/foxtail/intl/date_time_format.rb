# frozen_string_literal: true

require "date"
require "locale"
require "time"
require "tzinfo"
require "yaml"

module Foxtail
  module Intl
    # CLDR-based date and time formatter implementing Intl.DateTimeFormat functionality
    #
    # Uses Repository::DateTimeFormats and Repository::TimezoneNames for proper locale-specific formatting
    class DateTimeFormat
      # Create a new date/time formatter with fixed locale and options
      #
      # @param locale [Locale::Tag] The locale for formatting
      # @param options [Hash] Formatting options
      # @option options [String] :dateStyle Date formatting style ("full", "long", "medium", "short")
      # @option options [String] :timeStyle Time formatting style ("full", "long", "medium", "short")
      # @option options [String] :year Year format ("numeric", "2-digit")
      # @option options [String] :month Month format ("numeric", "2-digit", "long", "short", "narrow")
      # @option options [String] :day Day format ("numeric", "2-digit")
      # @option options [String] :weekday Weekday format ("long", "short", "narrow")
      # @option options [String] :hour Hour format ("numeric", "2-digit")
      # @option options [String] :minute Minute format ("numeric", "2-digit")
      # @option options [String] :second Second format ("numeric", "2-digit")
      # @option options [String] :timeZone Timezone identifier (e.g., "America/New_York", "Asia/Tokyo")
      # @option options [String] :timeZoneName Timezone name display ("long", "short")
      # @option options [Boolean] :hour12 Use 12-hour format (true) or 24-hour format (false)
      #
      # @example Basic date formatting
      #   formatter = Foxtail::Intl::DateTimeFormat.new(locale: Locale::Tag.parse("en-US"))
      #   formatter.call(Date.new(2023, 12, 25)) # => "12/25/2023"
      #
      # @example Date style formatting
      #   formatter = Foxtail::Intl::DateTimeFormat.new(
      #     locale: Locale::Tag.parse("en-US"),
      #     dateStyle: "full"
      #   )
      #   formatter.call(Date.new(2023, 12, 25)) # => "Monday, December 25, 2023"
      #
      # @example Time formatting
      #   formatter = Foxtail::Intl::DateTimeFormat.new(
      #     locale: Locale::Tag.parse("en-US"),
      #     timeStyle: "medium"
      #   )
      #   formatter.call(Time.new(2023, 12, 25, 14, 30)) # => "2:30:00 PM"
      #
      # @example Custom component formatting
      #   formatter = Foxtail::Intl::DateTimeFormat.new(
      #     locale: Locale::Tag.parse("ja"),
      #     year: "numeric",
      #     month: "long",
      #     day: "numeric"
      #   )
      #   formatter.call(Date.new(2023, 12, 25)) # => "2023年12月25日"
      #
      # @example Timezone formatting
      #   formatter = Foxtail::Intl::DateTimeFormat.new(
      #     locale: Locale::Tag.parse("en-US"),
      #     timeZone: "America/New_York",
      #     timeStyle: "full"
      #   )
      #   formatter.call(Time.now) # => "2:30:00 PM Eastern Standard Time"
      def initialize(locale:, **options)
        @locale = locale
        @options = options.dup.freeze
        @formats = Foxtail::CLDR::Repository::DateTimeFormats.new(locale)
        @timezone_names = Foxtail::CLDR::Repository::TimezoneNames.new(locale)
      end

      # Format a date/time with the configured locale and options
      #
      # @param value [Time, Date, DateTime, String, Numeric] The value to format
      # @raise [ArgumentError] when the value cannot be parsed as a date/time
      # @raise [Foxtail::CLDR::DataNotAvailable] when CLDR data is not available for the locale
      # @return [String] Formatted date/time string
      #
      # @example
      #   formatter = Foxtail::Intl::DateTimeFormat.new(
      #     locale: Locale::Tag.parse("en-US"),
      #     dateStyle: "full"
      #   )
      #   formatter.call(Date.new(2023, 12, 25)) # => "Monday, December 25, 2023"
      def call(value)
        # Keep original value for fallback when conversion fails
        @original_value = value

        # Parse and convert value to Time
        @original_time = convert_to_time(value)
        # Apply timezone conversion once during initialization
        utc_time = @original_time&.getutc
        @time_with_zone = apply_timezone(utc_time, @options[:timeZone])

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

      alias format call

      # Convert value to Time for consistent processing
      private def convert_to_time(value)
        case value
        when Time
          value
        when Date, DateTime
          value.to_time
        when String
          # Check for special value strings first
          if value == "Infinity" || value == "-Infinity" || value == "NaN"
            raise ArgumentError, "Cannot convert special value '#{value}' to time"
          end

          # Try to parse as timestamp first, then as date string
          # Check if it's a numeric string (Unix timestamp)
          if value.match?(/^\d+\.?\d*$/) || value.match?(/^[-+]?\d*\.?\d+([eE][-+]?\d+)?$/)
            timestamp = Float(value)

            # Check for special values after conversion
            if timestamp.infinite? || timestamp.nan?
              raise ArgumentError, "Cannot convert special value to time"
            end

            timestamp /= 1000.0 if timestamp > 1_000_000_000_000
            Time.at(timestamp)
          else
            Time.parse(value)
          end
        when Numeric
          # Check for special values first
          if value.infinite? || value.nan?
            raise ArgumentError, "Cannot convert special value to time"
          end

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
        @system_timezone ||= LocalTimezoneDetector.detect.id
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
          "GMT#{sign}#{hours}:#{"02d" % minutes}"
        end
      end

      # Get metazone ID for timezone ID
      private def timezone_to_metazone(timezone_id)
        @metazone_mapping ||= load_metazone_mapping
        @metazone_mapping[timezone_id]
      end

      # Load metazone mapping data
      private def load_metazone_mapping
        mapping_file = Foxtail.cldr_dir + "metazone_mapping.yml"

        return {} unless mapping_file.exist?

        begin
          yaml_data = YAML.load_file(mapping_file.to_s)
          yaml_data["timezone_to_metazone"] || {}
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
                         "EEE"   # Default to abbreviated, not single letter
                       end
        end

        # Day (d) - comes last for date fields
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

        # Time fields (H/h, m, s, a)
        if options[:hour]
          # Choose hour pattern based on hour12 setting and digit requirement
          hour_pattern = case [options[:hour], effective_hour12]
                         in ["numeric", false]
                           "H"
                         in ["2-digit", false]
                           "HH"
                         in ["numeric", true]
                           "h"
                         in ["2-digit", true]
                           "hh"
                         else
                           "h"
                         end
          key_parts << hour_pattern
        end

        if options[:minute]
          key_parts << case options[:minute]
                       when "numeric"
                         "m"
                       when "2-digit"
                         "mm"
                       else
                         "m"
                       end
        end

        if options[:second]
          key_parts << case options[:second]
                       when "numeric"
                         "s"
                       when "2-digit"
                         "ss"
                       else
                         "s"
                       end
        end

        # Add AM/PM marker if 12-hour format
        key_parts << "a" if options[:hour] && effective_hour12

        key_parts.join
      end

      # Format datetime using individual field specifications
      #
      # This method handles complex field combinations by trying to find
      # appropriate CLDR availableFormats patterns with hierarchical fallbacks.
      #
      # Strategy:
      # 1. Single field → Direct formatting (avoid pattern lookup overhead)
      # 2. Multiple fields → Try exact CLDR pattern match
      # 3. No exact match → Try simplified pattern fallbacks
      # 4. Still no match → Fall back to individual field formatting
      #
      # The fallback system enables Node.js Intl.DateTimeFormat compatibility
      # by finding the closest CLDR pattern and adapting it to user requirements.
      #
      # @return [String] Formatted datetime string
      private def format_with_fields
        # Check if this is a single field request - if so, format directly
        field_count = [
          @options[:year],
          @options[:month],
          @options[:day],
          @options[:weekday],
          @options[:hour],
          @options[:minute],
          @options[:second]
        ].count {|v| v }

        if field_count == 1
          # Single field - format directly without CLDR patterns
          return format_fields_individually
        end

        # Try to find appropriate CLDR availableFormats pattern
        pattern_key = generate_available_format_key(@options)
        available_pattern = @formats.available_format(pattern_key)

        # If exact pattern not found, try fallback patterns
        available_pattern ||= find_fallback_pattern(pattern_key)

        if available_pattern
          # Adapt pattern for 2-digit requirements
          adapted_pattern = adapt_pattern_for_options(available_pattern)
          # Use CLDR availableFormats pattern for proper ordering and separators
          format_with_pattern(adapted_pattern)
        else
          # Fallback to individual field formatting for unavailable patterns
          format_fields_individually
        end
      end

      # Find a fallback pattern by simplifying the pattern key
      #
      # This system implements a hierarchical pattern fallback strategy for CLDR
      # availableFormats when exact patterns don't exist:
      #
      # Example: {weekday: "long", year: "numeric", month: "short", day: "numeric"}
      # 1. Generate key: "yMMMEEEEd"
      # 2. Not found in CLDR → try simplifications
      # 3. Simplify "EEEE" → "E": "yMMMEd"
      # 4. Found in CLDR: "E, MMM d, y"
      # 5. Restore "E" → "EEEE": "EEEE, MMM d, y"
      # 6. Result: "Sunday, Jan 15, 2023" (Node.js compatible)
      #
      # @param original_key [String] The original pattern key (e.g., "yMMMEEEEd")
      # @return [String, nil] Adapted fallback pattern or nil
      private def find_fallback_pattern(original_key)
        # Map of simplifications to try (order matters - try most specific first)
        simplifications = [
          # Weekday simplifications
          %w[EEEE E],   # Full weekday → single letter
          %w[EEE E],    # Abbreviated weekday → single letter
          # Month simplifications
          %w[MMMM MMM], # Full month name → abbreviated
          %w[MMM M],    # Abbreviated month → numeric
          %w[MM M],     # 2-digit month → numeric
          # Day simplifications
          %w[dd d], # 2-digit day → numeric
          # Time field simplifications
          %w[mm m],     # 2-digit minute → numeric
          %w[ss s],     # 2-digit second → numeric
          %w[HH H],     # 2-digit hour → numeric
          %w[hh h],     # 2-digit 12-hour → numeric
          # Year simplifications
          %w[yyyy y],   # Full year → abbreviated
          %w[yy y]      # 2-digit year → abbreviated
        ]

        # Try single field simplifications first
        simplifications.each do |from, to|
          next unless original_key.include?(from)

          simplified_key = original_key.sub(from, to)
          pattern = @formats.available_format(simplified_key)

          if pattern
            # Restore the original format in the pattern
            return restore_original_format(pattern, from, to)
          end
        end

        # Try combinations of time field simplifications for "Hmmss" → "Hms"
        if original_key.match?(/H.*mm.*ss/)
          # Try simplifying both minute and second fields
          temp_key = original_key.sub("mm", "m").sub("ss", "s")
          pattern = @formats.available_format(temp_key)

          if pattern
            # Safe restoration using pattern parser
            parser = PatternParser::DateTime.new
            tokens = parser.parse(pattern)

            restored_tokens = tokens.map {|token|
              if token.is_a?(PatternParser::DateTime::FieldToken)
                case token.value
                when "m" then PatternParser::DateTime::FieldToken.new("mm")
                when "s" then PatternParser::DateTime::FieldToken.new("ss")
                else token
                end
              else
                token
              end
            }

            return restored_tokens.map(&:value).join
          end
        end

        # Try combinations of time field simplifications for "hmmss" → "hms" (12-hour format)
        if original_key.match?(/h.*mm.*ss/)
          # Try simplifying both minute and second fields for 12-hour format
          temp_key = original_key.sub("mm", "m").sub("ss", "s")
          pattern = @formats.available_format(temp_key)

          if pattern
            # Safe restoration using pattern parser
            parser = PatternParser::DateTime.new
            tokens = parser.parse(pattern)

            restored_tokens = tokens.map {|token|
              if token.is_a?(PatternParser::DateTime::FieldToken)
                case token.value
                when "m" then PatternParser::DateTime::FieldToken.new("mm")
                when "s" then PatternParser::DateTime::FieldToken.new("ss")
                else token
                end
              else
                token
              end
            }

            return restored_tokens.map(&:value).join
          end
        end

        # If still not found, try more aggressive simplifications
        try_aggressive_fallbacks(original_key)
      end

      # Restore the original format specifier in the found pattern
      #
      # Takes a simplified pattern found in CLDR and restores it to match
      # the original field specification requirements.
      #
      # Example:
      #   pattern: "E, MMM d, y"     (found with simplified "E")
      #   original_spec: "EEEE"      (user wanted full weekday)
      #   simplified_spec: "E"       (what we searched for)
      #   Result: "EEEE, MMM d, y"  (restored to user's requirements)
      #
      # Uses PatternParser for safe token-level replacement to avoid
      # accidentally replacing literals or other field types.
      #
      # @param pattern [String] The CLDR pattern found with simplified key
      # @param original_spec [String] Original field specification (e.g., "EEEE")
      # @param simplified_spec [String] Simplified specification used for search (e.g., "E")
      # @return [String] Pattern with original specification restored
      private def restore_original_format(pattern, original_spec, simplified_spec)
        # Use pattern parser to safely replace tokens
        parser = PatternParser::DateTime.new
        tokens = parser.parse(pattern)

        restored_tokens = tokens.map {|token|
          if token.is_a?(PatternParser::DateTime::FieldToken) && token.value == simplified_spec
            # Replace with original specification
            PatternParser::DateTime::FieldToken.new(original_spec)
          else
            token
          end
        }

        restored_tokens.map(&:value).join
      end

      # Try more aggressive fallbacks for complex patterns
      #
      # When simple field simplifications fail, this method tries common
      # pattern combinations that are likely to exist in CLDR data.
      #
      # Strategy:
      # 1. Check which fields the original pattern contains
      # 2. Try predefined common patterns that match those fields
      # 3. Adapt found pattern to original field specifications
      #
      # Example:
      #   original_key: "yMMMEEEEdd" (not found)
      #   → Try "yMMMEd" (common pattern)
      #   → Found: "E, MMM d, y"
      #   → Adapt: "EEEE, MMM dd, y" (restore original specs)
      #
      # @param original_key [String] The original pattern key that wasn't found
      # @return [String, nil] Adapted pattern or nil if no fallback found
      private def try_aggressive_fallbacks(original_key)
        # Check which fields we have
        has_year = original_key.include?("y")
        has_month = original_key.match?(/M+/)
        has_day = original_key.include?("d")
        has_weekday = original_key.match?(/E+/)
        has_hour = original_key.match?(/[Hh]+/)
        has_minute = original_key.match?(/m+/)
        has_second = original_key.match?(/s+/)
        has_ampm = original_key.include?("a")

        has_date_fields = has_year || has_month || has_day || has_weekday
        has_time_fields = has_hour || has_minute || has_second

        # If we only have time fields, try basic time patterns first
        if has_time_fields && !has_date_fields
          # Try exact basic time patterns that may have proper ordering
          # Priority order based on hour12 setting
          basic_time_patterns = []
          if has_hour && has_minute && has_second
            # For 12-hour format, prefer h patterns; for 24-hour, prefer H patterns
            basic_time_patterns += if effective_hour12
                                     %w[hms Hms] # 12-hour first
                                   else
                                     %w[Hms hms] # 24-hour first
                                   end
          elsif has_hour && has_minute
            basic_time_patterns += if effective_hour12
                                     %w[hm Hm]
                                   else
                                     %w[Hm hm]
                                   end
          elsif has_hour
            basic_time_patterns += if effective_hour12
                                     %w[h H]
                                   else
                                     %w[H h]
                                   end
          end

          # Try these patterns directly - they may have locale-specific ordering
          basic_time_patterns.each do |pattern_key|
            pattern = @formats.available_format(pattern_key)
            if pattern
              # For basic time patterns, use them as-is since they already have proper locale-specific ordering
              # Only adapt for 2-digit requirements without changing hour field type
              return adapt_pattern_for_options(pattern)
            end
          end
        end

        # If we have both date and time fields, try to combine them
        if has_date_fields && has_time_fields
          # Find a date pattern (without AM/PM)
          date_patterns = [
            "yMMMEd",  # Year, month, weekday, day
            "yMMMd",   # Year, month, day
            "yMd",     # Year, month (numeric), day
            "MMMEd",   # Month, weekday, day
            "MMMd",    # Month, day
            "MEd",     # Month (numeric), weekday, day
            "Md"       # Month (numeric), day
          ]

          date_pattern = nil
          date_patterns.each do |pattern_key|
            pattern_has_year = pattern_key.include?("y")
            pattern_has_month = pattern_key.match?(/M+/)
            pattern_has_day = pattern_key.include?("d")
            pattern_has_weekday = pattern_key.match?(/E+/)

            next if pattern_has_year && !has_year
            next if pattern_has_month && !has_month
            next if pattern_has_day && !has_day
            next if pattern_has_weekday && !has_weekday

            pattern = @formats.available_format(pattern_key)
            next unless pattern

            # Create date-only original key for adaptation
            date_only_key = original_key.gsub(/(?:a|([Hhms])\1*)/, "")
            date_pattern = adapt_fallback_pattern(pattern, date_only_key)
            break
          end

          # Find a time pattern (try basic patterns first for proper ordering)
          time_patterns = []
          if has_hour && has_minute && has_second
            time_patterns += effective_hour12 ? %w[hms Hms] : %w[Hms hms]
          elsif has_hour && has_minute
            time_patterns += effective_hour12 ? %w[hm Hm] : %w[Hm hm]
          elsif has_hour
            time_patterns += effective_hour12 ? %w[h H] : %w[H h]
          end

          time_pattern = nil
          time_patterns.each do |pattern_key|
            pattern = @formats.available_format(pattern_key)
            next unless pattern

            # Create time-only original key for adaptation
            time_only_key = ""
            time_only_key += original_key.match(/[Hh]+/)[0] if /[Hh]+/.match?(original_key)
            time_only_key += original_key.match(/m+/)[0] if /m+/.match?(original_key)
            time_only_key += original_key.match(/s+/)[0] if /s+/.match?(original_key)
            time_only_key += "a" if has_ampm

            time_pattern = adapt_fallback_pattern(pattern, time_only_key)
            break
          end

          # Combine date and time if both found
          if date_pattern && time_pattern
            return "#{date_pattern}, #{time_pattern}"
          end
        end

        # If we only have date fields, try date-only patterns
        if has_date_fields && !has_time_fields
          date_patterns = [
            "yMMMEd",  # Year, month, weekday, day
            "yMMMd",   # Year, month, day
            "yMd",     # Year, month (numeric), day
            "MMMEd",   # Month, weekday, day
            "MMMd",    # Month, day
            "MEd",     # Month (numeric), weekday, day
            "Md"       # Month (numeric), day
          ]

          date_patterns.each do |pattern_key|
            pattern_has_year = pattern_key.include?("y")
            pattern_has_month = pattern_key.match?(/M+/)
            pattern_has_day = pattern_key.include?("d")
            pattern_has_weekday = pattern_key.match?(/E+/)

            next if pattern_has_year && !has_year
            next if pattern_has_month && !has_month
            next if pattern_has_day && !has_day
            next if pattern_has_weekday && !has_weekday

            pattern = @formats.available_format(pattern_key)
            if pattern
              return adapt_fallback_pattern(pattern, original_key)
            end
          end
        end

        nil
      end

      # Adapt a fallback pattern to match the original field specifications
      private def adapt_fallback_pattern(pattern, original_key)
        # Extract original field specifications
        original_specs = extract_field_specs(original_key)

        # Parse the pattern
        parser = PatternParser::DateTime.new
        tokens = parser.parse(pattern)

        # Replace field tokens with original specifications
        adapted_tokens = tokens.map {|token|
          if token.is_a?(PatternParser::DateTime::FieldToken)
            field_type = token.field_type
            original_spec = original_specs[field_type]

            if original_spec
              PatternParser::DateTime::FieldToken.new(original_spec)
            else
              token
            end
          else
            token
          end
        }

        # Add AM/PM marker if needed and not already present
        if original_specs[:ampm] && adapted_tokens.none? {|t| t.is_a?(PatternParser::DateTime::FieldToken) && t.value == "a" }
          # Add AM/PM marker after time fields using proper token
          # Find the last time-related token position
          last_time_index = adapted_tokens.rindex {|t|
            t.is_a?(PatternParser::DateTime::FieldToken) &&
              (t.field_type == :hour || t.field_type == :minute || t.field_type == :second)
          }

          if last_time_index
            # Insert space and AM/PM marker after the last time field
            adapted_tokens.insert(last_time_index + 1, PatternParser::DateTime::LiteralToken.new(" "))
            adapted_tokens.insert(last_time_index + 2, PatternParser::DateTime::FieldToken.new("a"))
          else
            # Fallback: append at the end
            adapted_tokens << PatternParser::DateTime::LiteralToken.new(" ")
            adapted_tokens << PatternParser::DateTime::FieldToken.new("a")
          end
        end

        adapted_tokens.map(&:value).join
      end

      # Extract field specifications from pattern key
      private def extract_field_specs(pattern_key)
        specs = {}

        # Year
        if (match = pattern_key.match(/(y+)/))
          specs[:year] = match[1]
        end

        # Month
        if (match = pattern_key.match(/(M+)/))
          specs[:month] = match[1]
        end

        # Day
        if (match = pattern_key.match(/(d+)/))
          specs[:day] = match[1]
        end

        # Weekday
        if (match = pattern_key.match(/(E+)/))
          specs[:weekday] = match[1]
        end

        # Hour (check both H and h patterns)
        if (match = pattern_key.match(/([Hh]+)/))
          specs[:hour] = match[1]
        end

        # Minute
        if (match = pattern_key.match(/(m+)/))
          specs[:minute] = match[1]
        end

        # Second
        if (match = pattern_key.match(/(s+)/))
          specs[:second] = match[1]
        end

        # AM/PM marker
        if pattern_key.include?("a")
          specs[:ampm] = "a"
        end

        specs
      end

      # Adapt pattern to match option requirements (e.g., 2-digit padding)
      private def adapt_pattern_for_options(pattern)
        return pattern unless @options[:hour]

        parser = PatternParser::DateTime.new
        tokens = parser.parse(pattern)

        adapted_tokens = tokens.map {|token|
          if token.is_a?(PatternParser::DateTime::FieldToken) && token.field_type == :hour
            adapt_hour_field(token)
          else
            token
          end
        }

        adapted_tokens.map(&:value).join
      end

      # Adapt hour field token based on options
      #
      # Node.js Intl.DateTimeFormat behavior:
      # - hour: "numeric" → follow CLDR pattern defaults per locale
      # - hour: "2-digit" → always 2-digit padded
      #
      # Note: Different locales have different defaults for numeric hour:
      # - English: "HH" (2-digit) for "Hms" pattern
      # - Japanese: "H" (1-digit) for "Hms" pattern
      #
      # @param token [PatternParser::DateTime::FieldToken] The hour field token
      # @return [PatternParser::DateTime::FieldToken] Adapted token
      private def adapt_hour_field(token)
        case @options[:hour]
        when "2-digit"
          # Convert to 2-digit format
          case token.value
          when "H" then PatternParser::DateTime::FieldToken.new("HH")
          when "h" then PatternParser::DateTime::FieldToken.new("hh")
          when "K" then PatternParser::DateTime::FieldToken.new("KK")
          when "k" then PatternParser::DateTime::FieldToken.new("kk")
          else token
          end
        when "numeric"
          # Keep CLDR pattern default for numeric hour
          # Node.js behavior varies by locale but we follow CLDR patterns
          token
        else
          token
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
          # Adapt pattern for 2-digit requirements
          adapted_pattern = adapt_pattern_for_options(available_pattern)
          # Use CLDR available format pattern
          format_with_pattern(adapted_pattern)
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
          key_parts << if effective_hour12
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
        parser = PatternParser::DateTime.new
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
          when PatternParser::DateTime::FieldToken
            # Handle field tokens based on requested options
            adapted_token = adapt_field_token(token)
            adapted_tokens << adapted_token if adapted_token
          when PatternParser::DateTime::LiteralToken
            # Include literal tokens (separators, units) as-is for now
            # Will be filtered later based on adjacent field presence
            adapted_tokens << token
          when PatternParser::DateTime::QuotedToken
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
          # Show AM/PM if using 12-hour format (explicit or locale default)
          return nil unless effective_hour12

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
        pattern = if effective_hour12
                    # Use 12-hour format
                    @options[:hour] == "2-digit" ? "hh" : "h"
                  else
                    # Use 24-hour format
                    @options[:hour] == "2-digit" ? "HH" : "H"
                  end
        PatternParser::DateTime::FieldToken.new(pattern)
      end

      # Adapt minute token based on options
      private def adapt_minute_token(_token)
        # Always use 2-digit minutes for consistency
        PatternParser::DateTime::FieldToken.new("mm")
      end

      # Adapt second token based on options
      private def adapt_second_token(_token)
        # Always use 2-digit seconds for consistency
        PatternParser::DateTime::FieldToken.new("ss")
      end

      # Remove orphaned literal tokens between missing fields
      private def filter_orphaned_literals(tokens)
        result = []
        i = 0

        while i < tokens.length
          token = tokens[i]

          case token
          when PatternParser::DateTime::LiteralToken
            # Check if this literal is between two field tokens
            prev_is_field = i > 0 && tokens[i - 1].is_a?(PatternParser::DateTime::FieldToken)
            next_is_field = i < tokens.length - 1 && tokens[i + 1].is_a?(PatternParser::DateTime::FieldToken)

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
        parser = PatternParser::DateTime.new
        tokens = parser.parse(template)

        # Find the first literal token between time fields
        prev_was_time_field = false
        time_field_types = %i[hour minute second].freeze

        tokens.each do |token|
          case token
          when PatternParser::DateTime::FieldToken
            field_type = detect_field_type(token.value)
            prev_was_time_field = time_field_types.include?(field_type)
          when PatternParser::DateTime::LiteralToken
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
        parser = PatternParser::DateTime.new
        tokens = parser.parse(pattern)

        # Calculate various hour formats for 12-hour time
        hour_24 = @time_with_zone.hour
        hour_12_1_12 = if hour_24 == 0
                         12
                       else
                         (hour_24 > 12 ? hour_24 - 12 : hour_24)
                       end # 1-12 (h)
        hour_12_0_11 = hour_24 % 12 # 0-11 (K)
        hour_24_1_24 = hour_24 == 0 ? 24 : hour_24 # 1-24 (k)

        # Pre-compute lightweight C-level operations (strftime and to_s)
        fast_replacements = {
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
          "h" => hour_12_1_12.to_s,
          "KK" => hour_12_0_11.to_s.rjust(2, "0"),
          "K" => hour_12_0_11.to_s,
          "kk" => hour_24_1_24.to_s.rjust(2, "0"),
          "k" => hour_24_1_24.to_s,
          "mm" => @time_with_zone.strftime("%M"),
          "ss" => @time_with_zone.strftime("%S")
        }

        # Define method for on-demand computation of heavy operations
        get_field_value = ->(field) do
          # Check fast replacements first
          return fast_replacements[field] if fast_replacements.key?(field)

          # Heavy operations for fields not in fast_replacements
          case field
          when "EEEE" then @formats.weekday_name(weekday_key, "wide")
          when "EEE", "E" then @formats.weekday_name(weekday_key, "abbreviated")
          when "MMMM" then @formats.month_name(@time_with_zone.month, "wide")
          when "MMM" then @formats.month_name(@time_with_zone.month, "abbreviated")
          when "zzzz" then format_timezone_name(:long)
          when "z" then format_timezone_name(:short)
          when "VVV" then format_timezone_exemplar_city
          when "VV" then format_timezone_id
          when "ZZZZZ" then format_timezone_offset_iso
          when "Z" then format_timezone_offset_basic
          when "a" then @formats.day_period(@time_with_zone.hour)
          else field # Return the field itself if not found
          end
        end

        # Format each token according to its type
        tokens.map {|token|
          case token
          when PatternParser::DateTime::FieldToken
            get_field_value.call(token.value) || token.value
          when PatternParser::DateTime::LiteralToken
            token.value
          when PatternParser::DateTime::QuotedToken
            token.literal_text
          else
            token.value
          end
        }.join
      end

      # Format timezone name (z, zzzz)
      private def format_timezone_name(length)
        timezone_id = @options[:timeZone] || system_timezone

        # Try zone-specific name first
        name = find_zone_specific_name(timezone_id, length)
        return name if name

        # Try metazone-based name
        name = find_metazone_name(timezone_id, length)
        return name if name

        # Handle offset format timezones
        name = format_offset_timezone(timezone_id)
        return name if name

        # Final fallback to GMT/UTC offset format
        format_offset_fallback(timezone_id)
      end

      # Find zone-specific timezone name with DST consideration
      private def find_zone_specific_name(timezone_id, length)
        # Try daylight saving time specific name first
        if daylight_saving_time?(timezone_id)
          name = @timezone_names.zone_name(timezone_id, length, :daylight)
          return name if name
        end

        # Fall back to generic or standard names
        name = @timezone_names.zone_name(timezone_id, length, :generic) ||
               @timezone_names.zone_name(timezone_id, length, :standard)

        # Special handling for Etc/UTC: check if locale prefers different format
        return handle_etc_utc_special_case(timezone_id, length, name) if timezone_id == "Etc/UTC"

        name
      end

      # Handle special case for Etc/UTC timezone
      private def handle_etc_utc_special_case(timezone_id, length, existing_name)
        gmt_format = @timezone_names.gmt_format
        return existing_name unless gmt_format&.start_with?("UTC")

        offset_seconds = calculate_timezone_offset

        # For long format, prefer long zone name if available
        if length == :long
          long_name = @timezone_names.zone_name(timezone_id, :long, :standard)
          return long_name if long_name
          return gmt_format.gsub("{0}", "") if offset_seconds == 0
        end

        # For short format or non-zero offset
        if offset_seconds == 0
          gmt_format.gsub("{0}", "")
        else
          offset_string = format_gmt_offset_string(offset_seconds)
          gmt_format.gsub("{0}", offset_string)
        end
      end

      # Find metazone-based timezone name
      private def find_metazone_name(timezone_id, length)
        metazone_id = timezone_to_metazone(timezone_id)
        return nil unless metazone_id

        if metazone_id == "GMT"
          handle_gmt_metazone(metazone_id, length, timezone_id)
        else
          handle_regular_metazone(metazone_id, length, timezone_id)
        end
      end

      # Handle GMT metazone with special formatting rules
      private def handle_gmt_metazone(metazone_id, length, timezone_id)
        gmt_format = @timezone_names.gmt_format
        offset_seconds = calculate_timezone_offset

        # For long format, prefer localized metazone names
        if length == :long
          name = find_metazone_name_with_dst(metazone_id, length, timezone_id)
          return name if name
        end

        # Use UTC/GMT format if locale prefers UTC
        if gmt_format&.start_with?("UTC")
          if offset_seconds == 0
            gmt_format.gsub("{0}", "")
          else
            offset_string = format_gmt_offset_string(offset_seconds)
            gmt_format.gsub("{0}", offset_string)
          end
        elsif offset_seconds == 0
          # Use metazone name for GMT-preferring locales, considering DST
          # Standard GMT (no offset) - use standard or generic name
          @timezone_names.metazone_name(metazone_id, length, :standard) ||
          @timezone_names.metazone_name(metazone_id, length, :generic)
        else
          # Non-zero offset during GMT metazone - format with offset
          # This handles DST cases like London in summer (GMT+1)
          offset_string = format_gmt_offset_string(offset_seconds)
          gmt_format.gsub("{0}", offset_string)
        end
      end

      # Handle regular (non-GMT) metazones
      private def handle_regular_metazone(metazone_id, length, timezone_id)
        find_metazone_name_with_dst(metazone_id, length, timezone_id)
      end

      # Find metazone name considering daylight saving time
      private def find_metazone_name_with_dst(metazone_id, length, timezone_id)
        # Check for daylight saving time
        if daylight_saving_time?(timezone_id)
          name = @timezone_names.metazone_name(metazone_id, length, :daylight)
          return name if name
        end

        # Fall back to standard or generic metazone name
        @timezone_names.metazone_name(metazone_id, length, :standard) ||
        @timezone_names.metazone_name(metazone_id, length, :generic)
      end

      # Format offset-style timezone IDs (e.g., "+09:00")
      private def format_offset_timezone(timezone_id)
        return nil unless timezone_id.match?(/^[+-]\d{2}:\d{2}$/)

        format_gmt_offset_name(timezone_id)
      end

      # Final fallback to GMT/UTC offset format
      private def format_offset_fallback(timezone_id)
        offset_seconds = calculate_timezone_offset

        if offset_seconds == 0
          # Use base GMT or UTC format from CLDR
          base_format = @timezone_names.gmt_format
          base_format.gsub("{0}", "")
        else
          offset_string = format_gmt_offset_string(offset_seconds)
          # Apply CLDR gmt_format pattern (e.g., "GMT{0}" or "UTC{0}")
          gmt_pattern = @timezone_names.gmt_format
          gmt_pattern.gsub("{0}", offset_string)
        end
      rescue
        # Final fallback to timezone ID if offset calculation failed
        timezone_id
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
            calculate_tzinfo_offset(@options[:timeZone])
          end
        else
          # No explicit timezone option - use system timezone offset
          calculate_tzinfo_offset(system_timezone)
        end
      end

      # Determine effective hour12 setting (explicit option or locale default)
      private def effective_hour12
        return false if @options[:hour12] == false
        return true if @options[:hour12] == true

        # Default to locale preference when hour12 is nil
        locale_default_hour12?
      end

      # Determine locale default for hour12 format based on CLDR time patterns
      # If locale's short time pattern uses 'h' (12-hour), default to hour12=true
      # If it uses 'H' (24-hour), default to hour12=false
      private def locale_default_hour12?
        short_time_pattern = @formats.time_pattern("short")
        # Check if pattern contains lowercase 'h' (12-hour format indicator)
        short_time_pattern&.include?("h")
      end

      # Calculate timezone offset using TZInfo
      private def calculate_tzinfo_offset(timezone_id)
        timezone = TZInfo::Timezone.get(timezone_id)
        utc_time = @original_time.getutc
        period = timezone.period_for_utc(utc_time)
        period.offset.utc_total_offset
      end

      # Format offset seconds into GMT/UTC style string (e.g., "+9", "+9:30", "-5")
      private def format_gmt_offset_string(offset_seconds)
        return "" if offset_seconds == 0

        hours = offset_seconds.abs / 3600
        minutes = (offset_seconds.abs % 3600) / 60

        # Use CLDR hour_format pattern to get correct plus/minus signs
        # hour_format is like "+HH:mm;−HH:mm" where the minus is Unicode U+2212
        hour_format_pattern = @timezone_names.hour_format
        if hour_format_pattern
          # Split by semicolon to get positive and negative patterns
          patterns = hour_format_pattern.split(";")
          positive_pattern = patterns[0] || "+HH:mm"
          negative_pattern = patterns[1] || patterns[0]&.sub("+", "−") || "−HH:mm"

          # Extract the sign characters from patterns
          plus_sign = positive_pattern[/^[^Hm]+/] || "+"
          minus_sign = negative_pattern[/^[^Hm]+/] || "−"

          sign = offset_seconds >= 0 ? plus_sign : minus_sign
        else
          # Fallback to ASCII if no hour_format available
          sign = offset_seconds >= 0 ? "+" : "-"
        end

        offset_string = "#{sign}#{hours}"
        offset_string += ":#{"%02d" % minutes}" if minutes > 0
        offset_string
      end

      # Check if the current time is in daylight saving time for the given timezone
      private def daylight_saving_time?(timezone_id)
        return false unless @original_time

        # Handle special timezone IDs that don't use DST
        case timezone_id
        when "UTC", "GMT", %r{^Etc/UTC}, /^[+-]\d{2}:\d{2}$/
          return false
        end

        begin
          timezone = TZInfo::Timezone.get(timezone_id)
          utc_time = @original_time.getutc
          period = timezone.period_for_utc(utc_time)
          period.dst?
        rescue TZInfo::InvalidTimezoneIdentifier
          false
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
