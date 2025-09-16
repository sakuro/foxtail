# frozen_string_literal: true

require "locale"

module Foxtail
  module CLDR
    module Repository
      # CLDR timezone names data loader and processor
      #
      # Provides locale-specific timezone name information including display names,
      # abbreviations, and formatting with support for localized timezone names
      # for different types (standard, daylight, generic), exemplar cities,
      # and metazone names.
      #
      # @example
      #   locale = Locale::Tag.parse("ja")
      #   timezone_names = TimezoneNames.new(locale)
      #   timezone_names.zone_name("America/New_York", :long, :standard)  # => "北アメリカ東部標準時"
      #   timezone_names.exemplar_city("America/New_York")                # => "ニューヨーク"
      #   timezone_names.timezone_format(:hour_format)                   # => "+HH:mm;-HH:mm"
      #
      # @see https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Names
      class TimezoneNames < Base
        # Get localized timezone display name
        #
        # @param zone_id [String] IANA timezone identifier (e.g., "America/New_York", "Asia/Tokyo")
        # @param length [Symbol] Name length (:short, :long)
        # @param type [Symbol] Time type (:generic, :standard, :daylight)
        # @return [String, nil] Localized timezone name, or nil if not found
        def zone_name(zone_id, length, type)
          @resolver.resolve("timezone_names.zones.#{zone_id}.#{length}.#{type}", "timezone_names")
        end

        # Get exemplar city name for timezone
        #
        # @param zone_id [String] IANA timezone identifier
        # @return [String, nil] Localized city name, or nil if not found
        def exemplar_city(zone_id)
          @resolver.resolve("timezone_names.zones.#{zone_id}.exemplar_city", "timezone_names")
        end

        # Get metazone display name
        #
        # @param metazone_id [String] Metazone identifier (e.g., "America_Pacific", "Europe_Central")
        # @param length [Symbol] Name length (:short, :long)
        # @param type [Symbol] Time type (:generic, :standard, :daylight)
        # @return [String, nil] Localized metazone name, or nil if not found
        def metazone_name(metazone_id, length, type)
          @resolver.resolve("timezone_names.metazones.#{metazone_id}.#{length}.#{type}", "timezone_names")
        end

        # Get timezone format pattern
        #
        # @param format_type [Symbol] Format type (:hour_format, :gmt_format, :region_format,
        #                            :region_format_standard, :region_format_daylight, :fallback_format)
        # @return [String, nil] Format pattern, or nil if not found
        def timezone_format(format_type)
          @resolver.resolve("timezone_names.formats.#{format_type}", "timezone_names")
        end

        # Get all available timezone IDs for this locale
        #
        # @return [Array<String>] List of timezone IDs that have data
        def available_zones
          zones_data = @resolver.resolve("timezone_names.zones", "timezone_names")
          zones_data&.keys || []
        end

        # Get all available metazone IDs for this locale
        #
        # @return [Array<String>] List of metazone IDs that have data
        def available_metazones
          metazones_data = @resolver.resolve("timezone_names.metazones", "timezone_names")
          metazones_data&.keys || []
        end

        # Check if timezone name data exists for the given zone
        #
        # @param zone_id [String] IANA timezone identifier
        # @return [Boolean] True if data exists, false otherwise
        def zone_exists?(zone_id)
          zones_data = @resolver.resolve("timezone_names.zones", "timezone_names")
          zones_data&.key?(zone_id) || false
        end

        # Get timezone abbreviation (short name)
        #
        # @param zone_id [String] IANA timezone identifier
        # @param type [Symbol] Time type (:generic, :standard, :daylight)
        # @return [String, nil] Timezone abbreviation, or nil if not found
        def zone_abbreviation(zone_id, type=:generic)
          zone_name(zone_id, :short, type)
        end

        # Get GMT/UTC format pattern from CLDR data
        #
        # @return [String, nil] GMT format pattern (e.g., "GMT<tt>{0}</tt>", "UTC<tt>{0}</tt>"), or nil if not found
        def gmt_format
          @resolver.resolve("timezone_names.formats.gmt_format", "timezone_names")
        end

        # Get full timezone name (long name)
        #
        # @param zone_id [String] IANA timezone identifier
        # @param type [Symbol] Time type (:generic, :standard, :daylight)
        # @return [String, nil] Full timezone name, or nil if not found
        def zone_full_name(zone_id, type=:generic)
          zone_name(zone_id, :long, type)
        end

        # Format timezone offset using locale-specific pattern
        #
        # @param offset_seconds [Integer] Offset from UTC in seconds
        # @return [String] Formatted offset (e.g., "+09:00", "-05:00")
        def format_offset(offset_seconds)
          hour_format = timezone_format(:hour_format)
          return format_offset_default(offset_seconds) unless hour_format

          # Parse hour format pattern (e.g., "+HH:mm;-HH:mm")
          positive_pattern, negative_pattern = hour_format.split(";")

          if offset_seconds >= 0
            format_offset_with_pattern(offset_seconds, positive_pattern)
          else
            format_offset_with_pattern(-offset_seconds, negative_pattern)
          end
        end

        private def format_offset_default(offset_seconds)
          hours = offset_seconds.abs / 3600
          minutes = (offset_seconds.abs % 3600) / 60
          sign = offset_seconds >= 0 ? "+" : "-"
          "%s%02d:%02d" % [sign, hours, minutes]
        end

        private def format_offset_with_pattern(abs_offset_seconds, pattern)
          hours = abs_offset_seconds / 3600
          minutes = (abs_offset_seconds % 3600) / 60

          # Replace HH and mm in pattern
          pattern.gsub("HH", "%02d" % hours)
            .gsub("mm", "%02d" % minutes)
        end
      end
    end
  end
end
