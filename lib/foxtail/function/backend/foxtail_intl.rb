# frozen_string_literal: true

module Foxtail
  module Function
    module Backend
      # Foxtail-Intl backend using native Ruby CLDR implementation
      # Delegates formatting to Foxtail::Intl::NumberFormat and Foxtail::Intl::DateTimeFormat
      class FoxtailIntl < Base
        # Execute FTL function using Foxtail-Intl formatters
        # @param function_name [String] "NUMBER" or "DATETIME"
        # @param value [Object] Value to format
        # @param locale [Locale::Tag::Simple] Locale for formatting
        # @param options [Hash] Formatting options
        # @return [String] Formatted result
        # @raise [ArgumentError] For unknown functions or invalid values
        def call(function_name, value, locale:, **)
          case function_name.to_s.upcase
          when "NUMBER"
            format_number(value, locale:, **)
          when "DATETIME"
            format_datetime(value, locale:, **)
          else
            raise ArgumentError, "Unknown function: #{function_name}"
          end
        end

        # Check if Foxtail-Intl formatters are available
        # @return [Boolean] Always true since Foxtail-Intl is part of this gem
        def available?
          true
        end

        # Get backend name
        # @return [String] Backend name
        def name
          "Foxtail-Intl (native Ruby CLDR)"
        end

        private def format_number(value, locale:, **options)
          # Convert backend options to Foxtail::Intl::NumberFormat options
          intl_options = convert_number_options(options)
          formatter = Foxtail::Intl::NumberFormat.new(locale:, **intl_options)
          formatter.call(value)
        rescue ArgumentError
          raise # Re-raise ArgumentError from convert_number_options without wrapping
        rescue => e
          raise ArgumentError, "Number formatting failed: #{e.message}"
        end

        private def format_datetime(value, locale:, **options)
          # Convert backend options to Foxtail::Intl::DateTimeFormat options
          intl_options = convert_datetime_options(options)
          formatter = Foxtail::Intl::DateTimeFormat.new(locale:, **intl_options)
          formatter.call(value)
        rescue ArgumentError
          raise # Re-raise ArgumentError from convert_datetime_options without wrapping
        rescue => e
          raise ArgumentError, "DateTime formatting failed: #{e.message}"
        end

        # Convert Function backend options to Foxtail::Intl::NumberFormat options
        # @param options [Hash] Backend options
        # @return [Hash] Foxtail-Intl compatible options
        private def convert_number_options(options)
          intl_options = {}

          options.each do |key, value|
            case key
            when :style
              intl_options[:style] = value.to_s
            when :currency
              intl_options[:currency] = value.to_s
            when :minimumFractionDigits
              intl_options[:minimumFractionDigits] = Integer(value)
            when :maximumFractionDigits
              intl_options[:maximumFractionDigits] = Integer(value)
            when :notation
              intl_options[:notation] = value.to_s
            else
              raise ArgumentError, "Unknown number option: #{key}"
            end
          end

          intl_options
        end

        # Convert Function backend options to Foxtail::Intl::DateTimeFormat options
        # @param options [Hash] Backend options
        # @return [Hash] Foxtail-Intl compatible options
        private def convert_datetime_options(options)
          intl_options = {}

          options.each do |key, value|
            case key
            when :dateStyle
              intl_options[:dateStyle] = value.to_s
            when :timeStyle
              intl_options[:timeStyle] = value.to_s
            when :year, :month, :day, :weekday, :hour, :minute, :second
              intl_options[key] = value.to_s
            when :timeZone
              intl_options[:timeZone] = value.to_s
            when :timeZoneName
              intl_options[:timeZoneName] = value.to_s
            when :hour12
              intl_options[:hour12] = !!value
            else
              raise ArgumentError, "Unknown datetime option: #{key}"
            end
          end

          intl_options
        end
      end
    end
  end
end
