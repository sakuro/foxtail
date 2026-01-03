# frozen_string_literal: true

require "icu4x"

module Foxtail
  # Built-in formatting functions for FTL
  # Uses ICU4X for number and datetime formatting
  module Function
    # Default functions available to all bundles
    # @return [Hash{String => #call}] Function name to callable object mapping
    def self.defaults
      {
        "NUMBER" => method(:format_number),
        "DATETIME" => method(:format_datetime)
      }
    end

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
    # @param value [Time] Time to format
    # @param locale [ICU4X::Locale] Locale for formatting
    # @param options [Hash] Formatting options (camelCase keys)
    # @return [String] Formatted datetime
    private_class_method def self.format_datetime(value, locale:, **options)
      icu_options = convert_datetime_options(options)
      # ICU4X requires at least one of date_style or time_style
      # Default to :medium for date if neither specified
      icu_options[:date_style] ||= :medium unless icu_options[:time_style]
      ICU4X::DateTimeFormat.new(locale, **icu_options).format(value)
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
        when :minimumIntegerDigits
          result[:minimum_integer_digits] = Integer(value)
        when :minimumFractionDigits
          result[:minimum_fraction_digits] = Integer(value)
        when :maximumFractionDigits
          result[:maximum_fraction_digits] = Integer(value)
        when :useGrouping
          result[:use_grouping] = !!value
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
        when :timeZone
          result[:time_zone] = value.to_s
        end
      end

      result
    end
  end
end
