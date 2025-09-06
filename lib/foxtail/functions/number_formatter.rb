# frozen_string_literal: true

require "locale"
require_relative "../cldr/errors"
require_relative "../cldr/number_formats"

module Foxtail
  module Functions
    # CLDR-based number formatter implementing Intl.NumberFormat functionality
    class NumberFormatter
      # Format numbers with locale-specific formatting
      #
      # @raise [ArgumentError] when the value cannot be parsed as a number
      # @raise [CLDR::DataNotAvailable] when CLDR data is not available for the locale
      def call(*args, locale:, **options)
        # Locale is now guaranteed to be a Locale instance from Bundle/Resolver

        # Get the first positional argument (the value to format)
        value = args.first
        # Try to convert string numbers to numeric
        # Note: May raise ArgumentError for invalid numeric strings
        numeric_value =
          case value
          when Numeric then value
          when String
            Float(value)
          else
            return value.to_s
          end

        # Load CLDR number formats for the locale
        number_formats = CLDR::NumberFormats.new(locale)

        # Check if CLDR data is actually available for this locale
        unless number_formats.data?
          raise CLDR::DataNotAvailable, "CLDR data not available for locale: #{locale}"
        end

        # Convert options to formatting parameters
        formatted_value = Float(numeric_value)

        # Handle style options (decimal, percent, currency, scientific)
        style = options[:style] || "decimal"

        case style
        when "percent"
          format_percent(formatted_value, number_formats, options)
        when "currency"
          format_currency(formatted_value, number_formats, options)
        when "scientific"
          format_scientific(formatted_value, number_formats, options)
        else
          # Default decimal formatting
          format_number_with_precision(formatted_value, number_formats, options)
        end
      end

      private def format_percent(formatted_value, number_formats, options)
        # Format as percentage (multiply by 100)
        percent_value = formatted_value * 100
        result = format_number_with_precision(percent_value, number_formats, options)

        # Use CLDR pattern for percentage formatting
        pattern = number_formats.percent_pattern
        # Check if pattern has space before % by looking at the pattern structure
        if pattern.length >= 2 && pattern[-1] == "%" && pattern[-2] != "0"
          # There's a space or separator character before %, use it
          space_char = pattern[-2]
          "#{result}#{space_char}#{number_formats.percent_sign}"
        else
          "#{result}#{number_formats.percent_sign}"
        end
      end

      private def format_currency(formatted_value, number_formats, options)
        # Format as currency
        result = format_number_with_precision(formatted_value, number_formats, options)
        currency = options[:currency] || "$"
        currency_style = options[:currencyDisplay] || "standard"

        if currency_style == "accounting" && formatted_value < 0
          result = result.gsub(number_formats.minus_sign, "")
          "(#{currency}#{result})"
        else
          "#{currency}#{result}"
        end
      end

      private def format_scientific(formatted_value, number_formats, options)
        # Format in scientific notation
        format_scientific_notation(formatted_value, number_formats, options)
      end

      # Format number with precision and locale-specific symbols
      private def format_number_with_precision(value, number_formats, options)
        # Handle precision options
        if options[:minimumFractionDigits] || options[:maximumFractionDigits]
          min_digits = options[:minimumFractionDigits] || 0
          max_digits = options[:maximumFractionDigits]

          if max_digits
            # Format with max digits, then truncate trailing zeros down to minimum
            format_str = "%.#{max_digits}f"
            result = format_str % value

            # Remove trailing zeros, but keep at least min_digits
            if min_digits > 0
              decimal_part = result.split(".")[1] || ""
              # Remove trailing zeros but preserve at least min_digits
              decimal_part = decimal_part[0...-1] while decimal_part.length > min_digits && decimal_part.end_with?("0")
              result = "#{result.split(".")[0]}.#{decimal_part}"
            end
          else
            # Only minimum digits specified
            format_str = "%.#{min_digits}f"
            result = format_str % value
          end
        elsif value == Integer(value)
          # Integer formatting
          result = Integer(value).to_s
        else
          result = value.to_s
        end

        # Apply CLDR locale-specific symbols
        apply_cldr_symbols(result, number_formats)
      end

      # Apply CLDR locale-specific number symbols
      private def apply_cldr_symbols(result, number_formats)
        # Replace decimal separator
        result = result.gsub(".", number_formats.decimal_symbol)

        # Add thousand separators if the number is large enough
        parts = result.split(number_formats.decimal_symbol)
        integer_part = parts[0]
        decimal_part = parts[1]

        # Add grouping separators (every 3 digits from the right)
        if integer_part.length > 3
          # Handle negative numbers
          negative = integer_part.start_with?("-")
          integer_part = integer_part[1..] if negative

          # Add grouping separators
          integer_part = integer_part.reverse.gsub(/(\d{3})(?=\d)/, "\\1#{number_formats.group_symbol}").reverse

          # Add back negative sign if needed
          integer_part = number_formats.minus_sign + integer_part if negative
        end

        # Reconstruct the result
        if decimal_part
          "#{integer_part}#{number_formats.decimal_symbol}#{decimal_part}"
        else
          integer_part
        end
      end

      # Format number in scientific notation
      private def format_scientific_notation(value, number_formats, _options)
        # Simple scientific notation formatting
        if value == 0
          "0E0"
        else
          exponent = Math.log10(value.abs).floor
          mantissa = value / (10**exponent)

          # Format mantissa with locale symbols
          mantissa_str = apply_cldr_symbols(mantissa.to_s, number_formats)
          "#{mantissa_str}E#{exponent}"
        end
      end
    end
  end
end
