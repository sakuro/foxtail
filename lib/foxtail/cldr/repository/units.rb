# frozen_string_literal: true

require "locale"

module Foxtail
  module CLDR
    module Repository
      # CLDR unit data loader and processor
      #
      # Provides locale-specific unit information including display names,
      # patterns, and formatting with support for localized unit names
      # for different plural forms and widths.
      #
      # @example
      #   locale = Locale::Tag.parse("ja")
      #   units = Units.new(locale)
      #   units.unit_name("kilometer", :long)        # => "キロメートル"
      #   units.unit_pattern("kilometer", :long, :one) # => "<tt>{0}</tt> キロメートル"
      #   units.unit_category("kilometer")           # => "length"
      #
      # @see https://unicode.org/reports/tr35/tr35-general.html#Unit_Elements
      class Units < Base
        # Get localized unit display name
        #
        # @param unit [String] Unit name (e.g., "kilometer", "pound")
        # @param width [Symbol] Display width (:long, :short, :narrow)
        # @return [String] Localized unit name, or unit name if not found
        def unit_name(unit, width=:long)
          name = @resolver.resolve("units.#{unit}.#{width}.display_name", "units")
          name || unit
        end

        # Get unit pattern for specific count
        #
        # @param unit [String] Unit name
        # @param width [Symbol] Display width (:long, :short, :narrow)
        # @param count [Symbol] Plural form (:one, :other, etc.)
        # @return [String] Unit pattern with <tt>{0}</tt> placeholder, or nil if not found
        def unit_pattern(unit, width=:long, count=:other)
          @resolver.resolve("units.#{unit}.#{width}.#{count}", "units")
        end

        # Get unit category
        #
        # @param unit [String] Unit name
        # @return [String] Unit category (e.g., "length", "mass", "temperature")
        def unit_category(unit)
          @resolver.resolve("units.#{unit}.category", "units")
        end

        # Get unit gender (for grammatical gender in some languages)
        #
        # @param unit [String] Unit name
        # @param width [Symbol] Display width
        # @return [String] Gender (e.g., "masculine", "feminine", "neuter")
        def unit_gender(unit, width=:long)
          @resolver.resolve("units.#{unit}.#{width}.gender", "units")
        end

        # Get per-unit pattern (e.g., "per second")
        #
        # @param unit [String] Unit name
        # @param width [Symbol] Display width
        # @return [String] Per-unit pattern with <tt>{0}</tt> placeholder
        def per_unit_pattern(unit, width=:long)
          @resolver.resolve("units.#{unit}.#{width}.per_unit_pattern", "units")
        end

        # Get all available unit names for this locale
        #
        # @return [Array<String>] List of unit names
        def available_units
          units_data = @resolver.resolve("units", "units")
          units_data&.keys || []
        end

        # Check if unit data exists for the given unit
        #
        # @param unit [String] Unit name to check
        # @return [Boolean] True if unit data exists
        def unit_exists?(unit)
          !@resolver.resolve("units.#{unit}", "units").nil?
        end

        # Get all available widths for a unit
        #
        # @param unit [String] Unit name
        # @return [Array<Symbol>] List of available widths
        def available_widths(unit)
          unit_data = @resolver.resolve("units.#{unit}", "units")
          return [] unless unit_data

          keys = unit_data.keys.reject {|key| key == "category" }
          keys.map!(&:to_sym)
          keys
        end

        # Get all available counts for a unit and width
        #
        # @param unit [String] Unit name
        # @param width [Symbol] Display width
        # @return [Array<Symbol>] List of available counts
        def available_counts(unit, width=:long)
          width_data = @resolver.resolve("units.#{unit}.#{width}", "units")
          return [] unless width_data

          excluded_keys = %w[display_name gender per_unit_pattern]
          keys = width_data.keys.reject {|key| excluded_keys.include?(key) }
          keys.map!(&:to_sym)
          keys
        end
      end
    end
  end
end
