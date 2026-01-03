# frozen_string_literal: true

require "date"
require "icu4x"
require "time"

module Foxtail
  # Built-in formatting functions for FTL
  # Uses ICU4X for number and datetime formatting
  module Function
    # Default functions available to all bundles
    # Returns Method objects for NUMBER and DATETIME formatting
    def self.defaults
      {
        "NUMBER" => method(:format_number),
        "DATETIME" => method(:format_datetime)
      }
    end

    # Access individual function by name
    # @param name [String] Function name ("NUMBER" or "DATETIME")
    # @return [Proc] The function Proc that accepts (value, locale:, **options)
    def self.[](name) = defaults[name]

    # Format number using ICU4X
    # @param value [Numeric] Number to format
    # @param locale [ICU4X::Locale] Locale for formatting
    # @param options [Hash] Formatting options (camelCase keys)
    # @return [String] Formatted number
    private_class_method def self.format_number(value, locale:, **options)
      icu_options = convert_number_options(options)
      ICU4X::NumberFormat.new(locale, **icu_options).format(value)
    end

    # Format datetime using ICU4X
    # @param value [Time, DateTime, Date] DateTime to format
    # @param locale [ICU4X::Locale] Locale for formatting
    # @param options [Hash] Formatting options (camelCase keys)
    # @return [String] Formatted datetime
    private_class_method def self.format_datetime(value, locale:, **options)
      icu_options = convert_datetime_options(options)
      # ICU4X requires at least one of date_style or time_style
      # Default to :medium for date if neither specified
      icu_options[:date_style] ||= :medium unless icu_options[:time_style]
      time_value = to_time(value)
      ICU4X::DateTimeFormat.new(locale, **icu_options).format(time_value)
    end

    # Convert value to Time object
    # @param value [Time, DateTime, Date, String, Integer] Value to convert
    # @return [Time] Time object
    private_class_method def self.to_time(value)
      case value
      when Time
        value
      when DateTime, Date
        value.to_time
      when String
        Time.parse(value)
      when Integer
        Time.at(value)
      else
        raise ArgumentError, "Cannot convert #{value.class} to Time"
      end
    end

    # Convert FTL/JS style number options to ICU4X options
    # @param options [Hash] FTL/JS style options (camelCase)
    # @return [Hash] ICU4X style options (snake_case with symbols)
    private_class_method def self.convert_number_options(options)
      result = {}

      options.each do |key, value|
        case key
        when :style
          result[:style] = value.to_sym
        when :currency
          result[:currency] = value.to_s
        when :currencyDisplay
          result[:currency_display] = value.to_sym
        when :minimumIntegerDigits
          result[:minimum_integer_digits] = Integer(value)
        when :minimumFractionDigits
          result[:minimum_fraction_digits] = Integer(value)
        when :maximumFractionDigits
          result[:maximum_fraction_digits] = Integer(value)
        when :minimumSignificantDigits
          result[:minimum_significant_digits] = Integer(value)
        when :maximumSignificantDigits
          result[:maximum_significant_digits] = Integer(value)
        when :useGrouping
          result[:use_grouping] = !!value
          # Unsupported options are silently ignored for now
          # TODO: Add support as icu4x gem adds features
        end
      end

      result
    end

    # Convert FTL/JS style datetime options to ICU4X options
    # @param options [Hash] FTL/JS style options (camelCase)
    # @return [Hash] ICU4X style options (snake_case with symbols)
    private_class_method def self.convert_datetime_options(options)
      result = {}

      options.each do |key, value|
        case key
        when :dateStyle
          result[:date_style] = value.to_sym
        when :timeStyle
          result[:time_style] = value.to_sym
        when :year
          result[:year] = value.to_sym
        when :month
          result[:month] = value.to_sym
        when :day
          result[:day] = value.to_sym
        when :weekday
          result[:weekday] = value.to_sym
        when :hour
          result[:hour] = value.to_sym
        when :minute
          result[:minute] = value.to_sym
        when :second
          result[:second] = value.to_sym
        when :timeZone
          result[:time_zone] = value.to_s
        when :hour12
          result[:hour12] = !!value
          # Unsupported options are silently ignored for now
          # TODO: Add support as icu4x gem adds features
        end
      end

      result
    end
  end
end
