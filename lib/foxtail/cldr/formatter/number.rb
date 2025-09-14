# frozen_string_literal: true

require "bigdecimal"
require "locale"

module Foxtail
  module CLDR
    module Formatter
      # CLDR-based number formatter implementing Intl.NumberFormat functionality
      # Uses PatternParser::Number for proper token-based pattern processing
      class Number
        # Format numbers with locale-specific formatting
        #
        # @param args [Array] Positional arguments (first argument is the value to format)
        # @param locale [Locale::Tag] The locale for formatting
        # @param options [Hash] Formatting options
        # @option options [String] :style Format style ("decimal", "percent", "currency")
        # @option options [String] :notation Number notation ("standard", "scientific")
        # @option options [String] :pattern Custom CLDR pattern (overrides style and notation)
        # @option options [String] :currency Currency code for currency formatting (e.g., "USD", "JPY")
        # @option options [Integer] :minimumFractionDigits Minimum decimal places
        # @option options [Integer] :maximumFractionDigits Maximum decimal places
        # @raise [ArgumentError] when the value cannot be parsed as a number
        # @return [String] Formatted number string
        #
        # @example Basic decimal formatting
        #   formatter.call(1234.5, locale: Locale::Tag.parse("en-US"))
        #   # => "1,234.5"
        #
        # @example Currency formatting
        #   formatter.call(100, locale: Locale::Tag.parse("en-US"), style: "currency", currency: "USD")
        #   # => "$100.00"
        #
        # @example Scientific notation
        #   formatter.call(1234, locale: Locale::Tag.parse("en-US"), notation: "scientific")
        #   # => "1.234E3"
        #
        # @example Custom pattern with currency names
        #   formatter.call(100, locale: Locale::Tag.parse("en-US"), pattern: "#,##0.00 ¤¤¤", currency: "USD")
        #   # => "100.00 US dollars"
        def call(*args, locale:, **options)
          # Get the first positional argument (the value to format)
          value = args.first

          # Convert to BigDecimal for precise arithmetic
          decimal_value = convert_to_decimal(value)

          # Load CLDR number formats for the locale (will raise DataNotAvailable if data missing)
          number_formats = Foxtail::CLDR::Repository::NumberFormats.new(locale)

          # Determine the pattern to use
          pattern = determine_pattern(options, number_formats)

          # Apply style-specific transformations
          transformed_value = apply_style_transformations(decimal_value, options)

          # Format using token-based pattern processing
          # Pass original value in options for plural determination
          format_with_pattern(transformed_value, pattern, number_formats, options.merge(original_value: value))
        end

        private def convert_to_decimal(value)
          case value
          when BigDecimal
            value
          when Numeric
            BigDecimal(value.to_s)
          when String
            begin
              BigDecimal(value)
            rescue ArgumentError
              raise ArgumentError, "Invalid numeric string: #{value}"
            end
          else
            raise ArgumentError, "Cannot convert #{value.class} to number"
          end
        end

        # Determine which pattern to use based on options
        private def determine_pattern(options, number_formats)
          # Custom pattern takes priority
          return options[:pattern] if options[:pattern]

          style = options[:style] || "decimal"
          notation = options[:notation] || "standard"

          # Handle scientific and engineering notation with style consideration
          if notation == "scientific" || notation == "engineering"
            # Apply Node.js Intl.NumberFormat defaults for scientific notation
            if style == "percent"
              # For percent style scientific notation, Node.js uses maximumFractionDigits: 0
              options[:maximumFractionDigits] ||= 0
            else
              options[:maximumFractionDigits] ||= 3
            end

            # Combine scientific pattern with style-specific symbols
            base_pattern = number_formats.scientific_pattern
            return combine_pattern_with_style(base_pattern, style, number_formats, options)
          elsif notation == "compact"
            # Compact notation uses simplified patterns with abbreviations
            # For now, use decimal pattern as base - we'll handle the compacting in formatting
            return number_formats.decimal_pattern
          end

          # Style-based pattern selection for standard notation
          case style
          when "percent"
            number_formats.percent_pattern
          when "currency"
            currency_style = options[:currencyDisplay] == "accounting" ? "accounting" : "standard"
            pattern = number_formats.currency_pattern(currency_style)

            # Apply currency-specific decimal digits if not overridden by options
            currency_code = options[:currency] || "USD"
            unless options[:minimumFractionDigits] || options[:maximumFractionDigits]
              currency_digits = number_formats.currency_digits(currency_code)
              options[:minimumFractionDigits] = currency_digits
              options[:maximumFractionDigits] = currency_digits
            end

            pattern
          else
            number_formats.decimal_pattern
          end
        end

        # Apply style-specific value transformations
        private def apply_style_transformations(decimal_value, options)
          style = options[:style] || "decimal"
          case style
          when "currency"
            # Round to currency-specific decimal places
            if options[:maximumFractionDigits] == 0
              BigDecimal(decimal_value.round(0).to_s)
            else
              decimal_value
            end
          else
            # No multiplication here - handled in format_with_pattern
            decimal_value
          end
        end

        # Format value using pattern tokens
        private def format_with_pattern(decimal_value, pattern, number_formats, options)
          # Parse pattern into tokens
          parser = Foxtail::CLDR::PatternParser::Number.new
          tokens = parser.parse(pattern)

          # Split positive and negative patterns if present
          separator_index = tokens.find_index {|t| t.is_a?(Foxtail::CLDR::PatternParser::Number::PatternSeparatorToken) }

          # Always use absolute value for formatting (we handle sign separately)
          format_value = decimal_value.negative? ? decimal_value.abs : decimal_value

          if separator_index
            positive_tokens = tokens[0...separator_index]
            negative_tokens = tokens[(separator_index + 1)..]
            pattern_tokens = decimal_value.negative? ? negative_tokens : positive_tokens
          else
            pattern_tokens = tokens
          end

          # Apply all multiplications here (centralized logic)
          has_percent = pattern_tokens.any?(Foxtail::CLDR::PatternParser::Number::PercentToken)
          has_permille = pattern_tokens.any?(Foxtail::CLDR::PatternParser::Number::PerMilleToken)
          style = options[:style] || "decimal"

          # Apply multipliers based on pattern tokens or style
          if has_permille
            format_value *= 1000
          elsif has_percent || style == "percent"
            format_value *= 100
          end

          # Build formatted string from tokens
          # Pass original sign information via options
          original_was_negative = decimal_value.negative? && !separator_index
          build_formatted_string(
            format_value,
            pattern_tokens,
            number_formats,
            options.merge(original_was_negative:)
          )
        end

        # Build the final formatted string from tokens
        private def build_formatted_string(decimal_value, tokens, number_formats, options)
          # Analyze pattern structure first to check for scientific notation
          pattern_info = analyze_pattern_structure(tokens, **options)

          notation = options[:notation] || "standard"

          # Handle compact notation first (before scientific check)
          if notation == "compact"
            return format_compact_number(decimal_value, number_formats, options)
          end

          # Check if this is scientific notation (has ExponentToken)
          has_scientific = tokens.any?(Foxtail::CLDR::PatternParser::Number::ExponentToken)

          mantissa = decimal_value
          exponent = 0

          if has_scientific
            if notation == "engineering"
              # For engineering notation, normalize to mantissa form with exponent as multiple of 3
              normalized_result = normalize_for_engineering(decimal_value, pattern_info)
            else
              # For scientific notation, normalize the number to mantissa form (1-10 × 10^exp)
              normalized_result = normalize_for_scientific(decimal_value, pattern_info)
            end
            mantissa = normalized_result[:mantissa]
            exponent = normalized_result[:exponent]
            decimal_value = mantissa
          end

          # Convert to string for digit processing, avoiding scientific notation
          if has_scientific
            # For scientific notation, use mantissa for integer/fractional parts
            # Use floor to safely get integer part without precision loss
            integer_part = mantissa.abs.floor.to_s
            fractional_decimal = mantissa.abs - mantissa.abs.floor
            fractional_part = fractional_decimal.zero? ? "" : fractional_decimal.to_s.split(".")[1] || ""
          else
            value_str = decimal_value.to_s("F")
            parts = value_str.split(".")
            integer_part = parts[0] || "0"
            fractional_part = parts[1] || ""
          end

          # Format the number according to the pattern
          result = ""

          # Determine minus sign placement for negative numbers without explicit negative pattern
          if options[:original_was_negative]
            # Check if there's a space or other non-currency tokens between currency and digits
            has_separator_after_currency = pattern_info[:prefix_tokens].size > 1 &&
                                           pattern_info[:prefix_tokens].any? {|t| !t.is_a?(Foxtail::CLDR::PatternParser::Number::CurrencyToken) }

            if has_separator_after_currency
              # Currency name with separator: "¤¤¤ #,##0.00"
              # Pattern: [CurrencyToken("¤¤¤"), LiteralToken(" ")] + digits
              # Result:  "US dollar -1.00"
              #          ^^^^^^^^^^^   ^^^^^^
              #          prefix tokens minus+digits
              pattern_info[:prefix_tokens].each do |token|
                result += format_non_digit_token(token, number_formats, decimal_value, options)
              end
              result += number_formats.minus_sign
            else
              # Currency symbol without separator: "¤#,##0.00"
              # Pattern: [CurrencyToken("¤")] + digits
              # Result:  "-$1,234.50"
              #          ^ ^^^^^^^^^
              #          minus+prefix+digits
              result += number_formats.minus_sign
              pattern_info[:prefix_tokens].each do |token|
                result += format_non_digit_token(token, number_formats, decimal_value, options)
              end
            end
          else
            # Normal positive case - just process prefix tokens
            pattern_info[:prefix_tokens].each do |token|
              result += format_non_digit_token(token, number_formats, decimal_value, options)
            end
          end

          # Format the integer part with grouping
          result += format_integer_with_grouping(integer_part, pattern_info, number_formats)

          # Add decimal part if present
          if has_scientific
            # Round the mantissa to the specified number of fractional digits
            rounded_mantissa = mantissa.round(pattern_info[:fractional_digits])

            # Check if rounding caused overflow (regardless of fractional_digits value)
            notation = options[:notation] || "standard"
            overflow_threshold = notation == "engineering" ? 1000 : 10

            if rounded_mantissa.abs >= overflow_threshold
              # Adjust for overflow
              division_factor = notation == "engineering" ? 1000 : 10
              exponent_increment = notation == "engineering" ? 3 : 1

              mantissa = BigDecimal(rounded_mantissa) / BigDecimal(division_factor)
              exponent += exponent_increment
              # Recalculate integer and fractional parts
              new_str = mantissa.to_s("F")
              new_parts = new_str.split(".")
              # Replace the integer part in the result
              result = result[0...-integer_part.length] + new_parts[0]

              # Update rounded_mantissa for fractional part calculation
              rounded_mantissa = mantissa
            else
              # No overflow, but update integer part with rounded value
              rounded_integer_part = rounded_mantissa.abs.floor.to_s
              if rounded_integer_part != integer_part
                # Replace the integer part in the result with rounded value
                result = result[0...-integer_part.length] + rounded_integer_part
              end
            end

            # For scientific notation, respect maximumFractionDigits option
            if pattern_info[:fractional_digits] > 0
              rounded_str = rounded_mantissa.to_s("F")
              rounded_parts = rounded_str.split(".")
              rounded_fractional = rounded_parts[1] || ""

              if rounded_fractional.length > 0
                # Limit to maximumFractionDigits and remove trailing zeros
                limited_fractional = rounded_fractional[0...pattern_info[:fractional_digits]]
                trimmed_fractional = limited_fractional.gsub(/0+$/, "")
                if trimmed_fractional.length > 0
                  result += number_formats.decimal_symbol
                  result += trimmed_fractional
                end
              end
            end
          elsif pattern_info[:has_decimal] && fractional_part.length > 0 && pattern_info[:fractional_digits] > 0
            formatted_fractional = format_fractional_part(fractional_part, pattern_info)
            if formatted_fractional.length > 0
              result += number_formats.decimal_symbol
              result += formatted_fractional
            end
          elsif pattern_info[:has_decimal] && pattern_info[:required_fractional_digits] > 0
            # Show decimal separator and required zeros even if no fractional part
            result += number_formats.decimal_symbol
            result += "0" * pattern_info[:required_fractional_digits]
          end

          # Process non-digit tokens after digits
          pattern_info[:suffix_tokens].each do |token|
            result += if has_scientific && token.is_a?(Foxtail::CLDR::PatternParser::Number::ExponentToken)
                        format_exponent_token_with_value(token, exponent, number_formats)
                      else
                        format_non_digit_token(token, number_formats, decimal_value, options)
                      end
          end

          result
        end

        # Analyze the pattern structure to understand grouping and digit placement
        private def analyze_pattern_structure(tokens, **options)
          info = {
            prefix_tokens: [],
            suffix_tokens: [],
            integer_pattern: [],
            fractional_digits: 0,
            required_fractional_digits: 0,
            has_decimal: false,
            has_grouping: false
          }

          decimal_found = false
          digit_section_started = false

          tokens.each do |token|
            case token
            when Foxtail::CLDR::PatternParser::Number::DigitToken
              digit_section_started = true
              if decimal_found
                info[:fractional_digits] += token.digit_count
                # Count required digits (0) vs optional digits (#)
                if token.required?
                  info[:required_fractional_digits] += token.digit_count
                end
              else
                info[:integer_pattern] << token
              end
            when Foxtail::CLDR::PatternParser::Number::GroupToken
              if digit_section_started && !decimal_found
                info[:has_grouping] = true
                info[:integer_pattern] << token
              end
            when Foxtail::CLDR::PatternParser::Number::DecimalToken
              decimal_found = true
              info[:has_decimal] = true
            when Foxtail::CLDR::PatternParser::Number::ExponentToken
              # Scientific notation - handle separately
              info[:suffix_tokens] << token
            else
              # Non-digit tokens (currency, percent, literals, etc.)
              if digit_section_started
                info[:suffix_tokens] << token
              else
                info[:prefix_tokens] << token
              end
            end
          end

          # Override with precision options if provided
          if options[:minimumFractionDigits]
            info[:required_fractional_digits] = [info[:required_fractional_digits], options[:minimumFractionDigits]].max
            info[:fractional_digits] = [info[:fractional_digits], options[:minimumFractionDigits]].max
            info[:has_decimal] = true if options[:minimumFractionDigits] > 0
          end

          if options[:maximumFractionDigits]
            # For scientific/engineering notation patterns without explicit fractional digits (like #E0),
            # use the maximumFractionDigits value directly
            notation = options[:notation] || "standard"
            if info[:fractional_digits] == 0 && (notation == "scientific" || notation == "engineering")
              info[:fractional_digits] = options[:maximumFractionDigits]
              info[:has_decimal] = true if options[:maximumFractionDigits] > 0
            else
              info[:fractional_digits] = [info[:fractional_digits], options[:maximumFractionDigits]].min
            end

            # If maximum is 0, don't show decimals at all
            if options[:maximumFractionDigits] == 0
              info[:fractional_digits] = 0
              info[:required_fractional_digits] = 0
              info[:has_decimal] = false
            end
          end

          info
        end

        # Format integer part with proper grouping based on pattern
        private def format_integer_with_grouping(integer_part, pattern_info, number_formats)
          return integer_part unless pattern_info[:has_grouping]

          # Split integer into groups of 3 digits from right
          digit_groups = split_into_groups(integer_part)

          # Apply grouping separators
          digit_groups.join(number_formats.group_symbol)
        end

        # Split integer string into groups of 3 digits from the right
        private def split_into_groups(integer_str)
          # Remove any leading zeros except for the last digit
          clean_integer = integer_str.sub(/^0+(?=\d)/, "")
          clean_integer = "0" if clean_integer.empty?

          # Split into groups of 3 from the right
          groups = []
          while clean_integer.length > 3
            groups.unshift(clean_integer[-3..])
            clean_integer = clean_integer[0...-3]
          end
          groups.unshift(clean_integer) if clean_integer.length > 0

          groups
        end

        # Format fractional part with proper digit count
        private def format_fractional_part(fractional_part, pattern_info)
          total_digits = pattern_info[:fractional_digits]
          required_digits = pattern_info[:required_fractional_digits]

          if total_digits > 0
            # Pad to expected length
            padded = fractional_part.ljust(total_digits, "0")[0...total_digits]

            # Remove trailing zeros only beyond required digits
            if required_digits < total_digits
              # Keep at least required_digits, remove optional trailing zeros
              min_length = required_digits
              padded = padded[0...-1] while padded.length > min_length && padded.end_with?("0")
            end

            padded
          else
            fractional_part
          end
        end

        # Format non-digit tokens
        private def format_non_digit_token(token, number_formats, decimal_value, options)
          case token
          when Foxtail::CLDR::PatternParser::Number::CurrencyToken
            format_currency_token(token, number_formats, decimal_value, options)
          when Foxtail::CLDR::PatternParser::Number::PercentToken
            number_formats.percent_sign
          when Foxtail::CLDR::PatternParser::Number::PerMilleToken
            "‰"
          when Foxtail::CLDR::PatternParser::Number::ExponentToken
            format_exponent_token(token, decimal_value, number_formats)
          when Foxtail::CLDR::PatternParser::Number::LiteralToken
            token.value
          when Foxtail::CLDR::PatternParser::Number::QuotedToken
            token.literal_text
          when Foxtail::CLDR::PatternParser::Number::PlusToken
            "+"
          when Foxtail::CLDR::PatternParser::Number::MinusToken
            number_formats.minus_sign
          else
            ""
          end
        end

        # Format currency token
        private def format_currency_token(token, number_formats, decimal_value, options)
          currency_code = options[:currency] || "USD"

          case token.currency_type
          when :symbol
            number_formats.currency_symbol(currency_code)
          when :code
            currency_code
          when :name
            # CLDR ¤¤¤ pattern: Display currency names with plural-aware selection
            # See: https://unicode.org/reports/tr35/tr35-numbers.html#Currencies
            #
            # Examples (CLDR-compliant for English):
            #   1 → "US dollar" (integer, "one" category)
            #   2 → "US dollars" (integer > 1, "other" category)
            #   1.5 → "US dollars" (decimal, "other" category)
            #   1.0 → "US dollars" (visible decimal, "other" category per CLDR)
            #
            # Use original value for plural determination (not transformed value)
            original_value = options[:original_value] || decimal_value
            plural_rules = Foxtail::CLDR::Repository::PluralRules.new(number_formats.locale)
            plural_category = plural_rules.select(original_value)
            currency_names = number_formats.currency_names(currency_code)
            currency_names[plural_category.to_sym] || currency_names[:other] || currency_code
          end
        end

        # Format exponent token for scientific notation (deprecated - use format_exponent_token_with_value)
        private def format_exponent_token(token, decimal_value, number_formats)
          return "E0" if decimal_value.zero?

          # Calculate exponent
          abs_value = decimal_value.abs
          exponent = Math.log10(Float(abs_value)).floor

          # Format exponent with required digits
          exponent_str = exponent.abs.to_s.rjust(token.exponent_digits, "0")
          exponent_str = "#{number_formats.minus_sign}#{exponent_str}" if exponent.negative?
          exponent_str = "+#{exponent_str}" if exponent.positive? && token.show_exponent_sign?

          "E#{exponent_str}"
        end

        # Format exponent token with pre-calculated exponent value
        private def format_exponent_token_with_value(token, exponent, number_formats)
          return "E0" if exponent.zero?

          # Format exponent with required digits
          exponent_str = exponent.abs.to_s.rjust(token.exponent_digits, "0")
          exponent_str = "#{number_formats.minus_sign}#{exponent_str}" if exponent.negative?
          exponent_str = "+#{exponent_str}" if exponent.positive? && token.show_exponent_sign?

          "E#{exponent_str}"
        end

        # Normalize number for scientific notation (mantissa between 1-10)
        private def normalize_for_scientific(decimal_value, _pattern_info)
          return {mantissa: BigDecimal(0), exponent: 0} if decimal_value.zero?

          abs_value = decimal_value.abs

          # Calculate exponent to normalize mantissa between 1-10
          exponent = Math.log10(Float(abs_value)).floor

          # Calculate mantissa by dividing by 10^exponent
          mantissa = abs_value / (BigDecimal(10)**exponent)

          # Preserve sign
          mantissa = -mantissa if decimal_value.negative?

          {mantissa:, exponent:}
        end

        # Normalize number for engineering notation (mantissa between 1-1000, exponent multiple of 3)
        private def normalize_for_engineering(decimal_value, _pattern_info)
          return {mantissa: BigDecimal(0), exponent: 0} if decimal_value.zero?

          abs_value = decimal_value.abs

          # Calculate exponent to normalize mantissa between 1-10 first
          raw_exponent = Math.log10(Float(abs_value)).floor

          # Adjust exponent to be multiple of 3
          # Engineering notation uses exponents: ..., -6, -3, 0, 3, 6, 9, ...
          engineering_exponent = (raw_exponent / 3.0).floor * 3

          # Calculate mantissa by dividing by 10^engineering_exponent
          mantissa = abs_value / (BigDecimal(10)**engineering_exponent)

          # Preserve sign
          mantissa = -mantissa if decimal_value.negative?

          {mantissa:, exponent: engineering_exponent}
        end

        # Format number using compact notation based on CLDR data
        private def format_compact_number(decimal_value, number_formats, options)
          style = options[:style] || "decimal"

          # Note: Percent multiplication already applied in format_number method (line 168-170)

          # Handle zero value with style
          if decimal_value.zero?
            case style
            when "currency"
              currency_code = options[:currency] || "USD"
              symbol = number_formats.currency_symbol(currency_code)
              return "#{symbol}0"
            when "percent"
              return "0%"
            else
              return "0"
            end
          end

          compact_display = options[:compactDisplay] || "short"
          compact_info = find_compact_pattern(decimal_value, number_formats, compact_display)

          if compact_info.nil?
            # No compacting - format with appropriate decimal places and apply style
            original_negative = options[:original_was_negative] || false

            if decimal_value.abs < 1 && decimal_value.abs > 0
              # For small decimal values, use Node.js compact notation defaults:
              # maximumSignificantDigits: 2, minimumSignificantDigits: 1
              formatted = "%.2g" % decimal_value.abs
            else
              # For integer values, round first then format
              # Apply rounding to original signed value for correct result
              original_value = original_negative ? -decimal_value : decimal_value
              rounded_value = original_value.round
              formatted = rounded_value.abs.to_s
              if rounded_value.negative?
                formatted = number_formats.minus_sign + formatted
              end
              # Apply style to the formatted number
              return apply_style_to_compact_result(formatted, style, number_formats, options)
            end

            # Apply sign and style
            if original_negative
              formatted = number_formats.minus_sign + formatted
            end
            return apply_style_to_compact_result(formatted, style, number_formats, options)
          end

          # Apply the pattern (handles positive value)
          formatted_number = apply_compact_pattern(decimal_value.abs, compact_info)

          # Preserve original sign using passed option
          original_negative = options[:original_was_negative] || false
          if original_negative
            formatted_number = number_formats.minus_sign + formatted_number
          end

          # Apply style to compact result
          apply_style_to_compact_result(formatted_number, style, number_formats, options)
        end

        # Find the appropriate compact pattern from CLDR data
        private def find_compact_pattern(decimal_value, number_formats, compact_display)
          abs_value = decimal_value.abs.to_f
          patterns = number_formats.compact_patterns(compact_display)

          return nil if patterns.empty?

          # Find the best matching pattern by magnitude
          # CLDR patterns are keyed by magnitude (e.g., "1000", "10000", "100000")
          # Each magnitude represents the threshold where that pattern starts being used
          best_magnitude = nil
          best_divisor = 1

          # Sort magnitudes in ascending order and find the highest one that the value reaches
          magnitudes = patterns.keys.map { |k| Integer(k, 10) }.sort
          magnitudes.each do |magnitude|
            # Value must be >= magnitude to use this pattern
            next if abs_value < magnitude

            best_magnitude = magnitude.to_s
            best_divisor = magnitude
            # Continue to find the highest applicable magnitude
          end

          return nil unless best_magnitude

          pattern = number_formats.compact_pattern(best_magnitude, compact_display, "other")
          return nil unless pattern

          # Find the base divisor for this unit by finding the smallest magnitude with the same unit
          base_divisor = find_base_divisor_for_unit(pattern, patterns)

          {
            pattern:,
            divisor: base_divisor,
            magnitude: best_magnitude
          }
        end

        # Apply CLDR compact pattern (e.g., "0万", "0K") to format the number
        private def apply_compact_pattern(decimal_value, compact_info)
          # Note: decimal_value should already be positive (abs applied by caller)
          scaled_value = Float(decimal_value) / compact_info[:divisor]
          pattern = compact_info[:pattern]

          # Count zeros in pattern to determine how many digits to show
          zero_count = pattern.count("0")

          # Format number based on the pattern's zero count
          formatted_number = if zero_count == 1
                               # Pattern like "0K" - show 1 significant digit with decimal if needed
                               format_compact_single_digit(scaled_value)
                             else
                               # Pattern like "00K", "000K" - show integer with appropriate digits
                               format_compact_multiple_digits(scaled_value, zero_count)
                             end

          # Replace zeros in pattern with formatted number
          pattern.sub(/0+/, formatted_number)
        end

        # Format scaled value for single-digit compact patterns (e.g., "0K")
        private def format_compact_single_digit(scaled_value)
          if scaled_value >= 10
            scaled_value.round.to_s
          elsif scaled_value.round(1) == scaled_value.round
            scaled_value.round.to_s
          else
            "%.1f" % scaled_value.round(1)
          end
        end

        # Format scaled value for multi-digit compact patterns (e.g., "00K", "000K")
        private def format_compact_multiple_digits(scaled_value, _zero_count)
          # For multi-digit patterns, show integer value
          scaled_value.round.to_s
        end

        # Find the base divisor for a unit by finding the smallest magnitude with the same unit symbol
        private def find_base_divisor_for_unit(target_pattern, all_patterns)
          # Extract unit symbol from target pattern (everything after the zeros)
          unit_symbol = target_pattern.gsub(/0+/, "")

          # If there's no unit symbol (pattern is just "0"), this means no compacting
          return 1 if unit_symbol.empty?

          # Find all patterns with the same unit symbol and get their magnitudes
          same_unit_magnitudes = []
          all_patterns.each do |magnitude_str, count_patterns|
            count_patterns.each_value do |pattern|
              pattern_unit = pattern.gsub(/0+/, "")
              if pattern_unit == unit_symbol
                same_unit_magnitudes << Integer(magnitude_str, 10)
              end
            end
          end

          # Return the smallest magnitude for this unit (that's the base divisor)
          same_unit_magnitudes.min || 1
        end

        # Combine scientific pattern with style-specific symbols
        private def combine_pattern_with_style(base_pattern, style, number_formats, options)
          case style
          when "currency"
            # Add currency symbol to scientific pattern: ¤#E0
            "¤#{base_pattern}"
          when "percent"
            # Add percent symbol to scientific pattern: #E0%
            "#{base_pattern}%"
          else
            base_pattern
          end
        end

        # Apply style formatting to compact notation result
        private def apply_style_to_compact_result(formatted_number, style, number_formats, options)
          case style
          when "currency"
            currency_code = options[:currency] || "USD"
            symbol = number_formats.currency_symbol(currency_code)
            "#{symbol}#{formatted_number}"
          when "percent"
            # For percent style, the number should be multiplied by 100
            # But in compact notation context, we treat it as already formatted
            "#{formatted_number}%"
          else
            formatted_number
          end
        end
      end
    end
  end
end
