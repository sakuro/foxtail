# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/math"
require "locale"

module Foxtail
  module CLDR
    module Formatter
      # CLDR-based number formatter implementing Intl.NumberFormat functionality
      #
      # Uses PatternParser::Number for proper token-based pattern processing
      class Number
        # Create a new number formatter with fixed locale and options
        #
        # @param locale [Locale::Tag] The locale for formatting
        # @param options [Hash] Formatting options
        # @option options [String] :style Format style ("decimal", "percent", "currency")
        # @option options [String] :notation Number notation ("standard", "scientific")
        # @option options [String] :pattern Custom CLDR pattern (overrides style and notation)
        # @option options [String] :currency Currency code for currency formatting (e.g., "USD", "JPY")
        # @option options [Integer] :minimumFractionDigits Minimum decimal places
        # @option options [Integer] :maximumFractionDigits Maximum decimal places
        #
        # @example Basic decimal formatting
        #   formatter = Foxtail::CLDR::Formatter::Number.new(locale: Locale::Tag.parse("en-US"))
        #   formatter.call(1234.5) # => "1,234.5"
        #
        # @example Currency formatting
        #   formatter = Foxtail::CLDR::Formatter::Number.new(
        #     locale: Locale::Tag.parse("en-US"),
        #     style: "currency",
        #     currency: "USD"
        #   )
        #   formatter.call(100) # => "$100.00"
        #
        # @example Scientific notation
        #   formatter = Foxtail::CLDR::Formatter::Number.new(
        #     locale: Locale::Tag.parse("en-US"),
        #     notation: "scientific"
        #   )
        #   formatter.call(1234) # => "1.234E3"
        def initialize(locale:, **options)
          @locale = locale
          @options = options.dup
          @formats = Foxtail::CLDR::Repository::NumberFormats.new(locale)

          # Initialize Currency repository if needed
          if use_currency?(options)
            @currencies = Foxtail::CLDR::Repository::Currencies.new(locale)
          end

          # Initialize Units repository if needed
          if use_units?(options)
            @units = Foxtail::CLDR::Repository::Units.new(locale)
          end

          # Apply style-specific option defaults
          style = @options[:style] || "decimal"
          notation = @options[:notation] || "standard"

          # Apply scientific notation defaults first (takes precedence over currency defaults)
          if notation == "scientific" || notation == "engineering"
            # Apply Node.js Intl.NumberFormat defaults for scientific notation
            # For percent style scientific notation, Node.js uses maximumFractionDigits: 0
            @options[:maximumFractionDigits] ||= (style == "percent" ? 0 : 3)
          end

          # Apply currency-specific decimal digits if not overridden by options or scientific notation
          if style == "currency"
            currency_code = @options[:currency] || "USD"
            unless @options[:minimumFractionDigits] || @options[:maximumFractionDigits]
              currency_digits = @formats.currency_digits(currency_code)
              @options[:minimumFractionDigits] = currency_digits
              @options[:maximumFractionDigits] = currency_digits
            end
          end

          @options.freeze
        end

        # Format a number with the configured locale and options
        #
        # @param value [Numeric, String] The value to format
        # @raise [ArgumentError] when the value cannot be parsed as a number
        # @return [String] Formatted number string
        #
        # @example
        #   formatter = Foxtail::CLDR::Formatter::Number.new(
        #     locale: Locale::Tag.parse("en-US"),
        #     style: "currency",
        #     currency: "USD"
        #   )
        #   formatter.call(100) # => "$100.00"
        def call(value)
          # Keep original value for plural rule determination (1 vs 1.0 matters in some locales)
          @original_value = value
          @decimal_value = convert_to_decimal(value)

          format
        end

        # Format the number value using CLDR data and options
        def format
          # Handle special values (Infinity, -Infinity, NaN) early
          if special_value?(@original_value)
            return format_special_value(@original_value)
          end

          # Apply style-specific transformations
          transformed_value = apply_style_transformations

          pattern = determine_pattern
          # Parse pattern into tokens
          parser = Foxtail::CLDR::PatternParser::Number.new
          tokens = parser.parse(pattern)

          # Split positive and negative patterns if present
          # Always use absolute value for formatting (we handle sign separately)
          format_value = transformed_value.negative? ? transformed_value.abs : transformed_value

          pattern_tokens, has_separator =
            case tokens
            in [*positive, Foxtail::CLDR::PatternParser::Number::PatternSeparatorToken, *negative]
              # Pattern with positive and negative forms (e.g., "#,##0.00;(#,##0.00)")
              [transformed_value.negative? ? negative : positive, true]
            in _
              # Pattern with only positive form
              [tokens, false]
            end

          # Check for percent and permille tokens to apply multiplication
          has_percent = tokens.any?(Foxtail::CLDR::PatternParser::Number::PercentToken)
          has_permille = tokens.any?(Foxtail::CLDR::PatternParser::Number::PerMilleToken)
          style = @options[:style] || "decimal"

          # Apply percent/permille multiplier
          if has_permille || style == "permille"
            format_value *= 1000
          elsif has_percent || style == "percent"
            format_value *= 100
          end

          # Build formatted string from tokens
          # Pass original sign information via options
          original_was_negative = transformed_value.negative? && !has_separator
          build_formatted_string(format_value, pattern_tokens, original_was_negative)
        end

        # Check if currency repository is needed (any currency symbol ¤, ¤¤, ¤¤¤)
        private def use_currency?(options)
          # Check for currency style
          style = options[:style]
          return true if style == "currency"

          # Check custom pattern for currency tokens using proper token parsing
          pattern = options[:pattern]
          if pattern
            parser = Foxtail::CLDR::PatternParser::Number.new
            tokens = parser.parse(pattern)
            return tokens.any?(Foxtail::CLDR::PatternParser::Number::CurrencyToken)
          end

          false
        end

        private def use_units?(options)
          # Check for unit style
          style = options[:style]
          style == "unit"
        end

        private def convert_to_decimal(original_value)
          case original_value
          when BigDecimal
            original_value
          when Numeric
            BigDecimal(original_value.to_s)
          when String
            begin
              BigDecimal(original_value)
            rescue ArgumentError
              raise ArgumentError, "Invalid numeric string: #{original_value}"
            end
          else
            raise ArgumentError, "Cannot convert #{original_value.class} to number"
          end
        end

        # Determine which pattern to use based on options
        private def determine_pattern
          # Custom pattern takes priority
          return @options[:pattern] if @options[:pattern]

          style = @options[:style] || "decimal"
          notation = @options[:notation] || "standard"

          # Handle scientific and engineering notation with style consideration
          if notation == "scientific" || notation == "engineering"
            # Combine scientific pattern with style-specific symbols
            base_pattern = @formats.scientific_pattern
            return combine_pattern_with_style(base_pattern, style)
          elsif notation == "compact"
            # Compact notation uses simplified patterns with abbreviations
            # Use decimal pattern as base but apply style-specific symbols
            base_pattern = @formats.decimal_pattern
            return combine_pattern_with_style(base_pattern, style)
          end

          # Style-based pattern selection for standard notation
          case style
          when "percent"
            @formats.percent_pattern
          when "currency"
            currency_style = @options[:currencyDisplay] == "accounting" ? "accounting" : "standard"
            @formats.currency_pattern(currency_style)
          else
            # Use decimal pattern for unit, decimal, and default cases
            @formats.decimal_pattern
          end
        end

        # Apply style-specific value transformations
        private def apply_style_transformations
          # Round to currency-specific decimal places for zero-precision currencies (e.g., JPY)
          if @options[:style] == "currency" && @options[:maximumFractionDigits] == 0
            BigDecimal(@decimal_value.round(0).to_s)
          else
            @decimal_value
          end
        end

        # Build the final formatted string from tokens
        private def build_formatted_string(format_value, tokens, original_was_negative)
          # Analyze pattern structure first to check for scientific notation
          pattern_info = analyze_pattern_structure(tokens)

          notation = @options[:notation] || "standard"

          # Handle compact notation first (before scientific check)
          if notation == "compact"
            return format_compact_number(format_value, original_was_negative)
          end

          # Check if this is scientific notation (has ExponentToken)
          has_scientific = tokens.any?(Foxtail::CLDR::PatternParser::Number::ExponentToken)

          mantissa = format_value
          exponent = 0

          if has_scientific
            normalized_result =
              if notation == "engineering"
                # For engineering notation, normalize to mantissa form with exponent as multiple of 3
                normalize_for_engineering(format_value, pattern_info)
              else
                # For scientific notation, normalize the number to mantissa form (1-10 × 10^exp)
                normalize_for_scientific(format_value, pattern_info)
              end
            mantissa = normalized_result[:mantissa]
            exponent = normalized_result[:exponent]
            format_value = mantissa
          end

          # Convert to string for digit processing, avoiding scientific notation
          if has_scientific
            # For scientific notation, use mantissa for integer/fractional parts
            # Use floor to safely get integer part without precision loss
            integer_part = mantissa.abs.floor.to_s
            fractional_decimal = mantissa.abs - mantissa.abs.floor
            fractional_part = fractional_decimal.zero? ? "" : fractional_decimal.to_s.split(".")[1] || ""
          else
            value_str = format_value.to_s("F")
            parts = value_str.split(".")
            integer_part = parts[0] || "0"
            fractional_part = parts[1] || ""
          end

          # Format the number according to the pattern
          result = ""

          # Determine minus sign placement for negative numbers without explicit negative pattern
          if original_was_negative
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
                result += format_non_digit_token(token, format_value)
              end
              result += @formats.minus_sign
            else
              # Currency symbol without separator: "¤#,##0.00"
              # Pattern: [CurrencyToken("¤")] + digits
              # Result:  "-$1,234.50"
              #          ^ ^^^^^^^^^
              #          minus+prefix+digits
              result += @formats.minus_sign
              pattern_info[:prefix_tokens].each do |token|
                result += format_non_digit_token(token, format_value)
              end
            end
          else
            # Normal positive case - just process prefix tokens
            pattern_info[:prefix_tokens].each do |token|
              result += format_non_digit_token(token, format_value)
            end
          end

          # Format the integer part with grouping
          result += format_integer_with_grouping(integer_part, pattern_info)

          # Add decimal part if present
          if has_scientific
            # Round the mantissa to the specified number of fractional digits
            rounded_mantissa = mantissa.round(pattern_info[:fractional_digits])

            # Check if rounding caused overflow (regardless of fractional_digits value)
            notation = @options[:notation] || "standard"
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
                  result += @formats.decimal_symbol
                  result += trimmed_fractional
                end
              end
            end
          elsif pattern_info[:has_decimal] && fractional_part.length > 0 && pattern_info[:fractional_digits] > 0
            formatted_fractional = format_fractional_part(fractional_part, pattern_info)
            if formatted_fractional.length > 0
              result += @formats.decimal_symbol
              result += formatted_fractional
            end
          elsif pattern_info[:has_decimal] && pattern_info[:required_fractional_digits] > 0
            # Show decimal separator and required zeros even if no fractional part
            result += @formats.decimal_symbol
            result += "0" * pattern_info[:required_fractional_digits]
          end

          # Process non-digit tokens after digits
          pattern_info[:suffix_tokens].each do |token|
            result += if has_scientific && token.is_a?(Foxtail::CLDR::PatternParser::Number::ExponentToken)
                        format_exponent_token_with_value(token, exponent)
                      else
                        format_non_digit_token(token, format_value)
                      end
          end

          # Apply unit pattern for unit style
          style = @options[:style] || "decimal"
          if style == "unit"
            unit = @options[:unit] || "meter"
            unit_display = @options[:unitDisplay] || "short"
            unit_pattern = @units.unit_pattern(unit, unit_display.to_sym, :other)

            if unit_pattern
              # Replace {0} placeholder with the formatted number
              result = unit_pattern.gsub("{0}", result)
            else
              # Fallback: append unit name if no pattern found
              result += " #{unit}"
            end
          end

          result
        end

        # Analyze the pattern structure to understand grouping and digit placement
        private def analyze_pattern_structure(tokens)
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
          if @options[:minimumFractionDigits]
            info[:required_fractional_digits] = [info[:required_fractional_digits], @options[:minimumFractionDigits]].max
            info[:fractional_digits] = [info[:fractional_digits], @options[:minimumFractionDigits]].max
            info[:has_decimal] = true if @options[:minimumFractionDigits] > 0
          end

          if @options[:maximumFractionDigits]
            # For scientific/engineering notation patterns without explicit fractional digits (like #E0),
            # use the maximumFractionDigits value directly
            notation = @options[:notation] || "standard"
            if info[:fractional_digits] == 0 && (notation == "scientific" || notation == "engineering")
              info[:fractional_digits] = @options[:maximumFractionDigits]
              info[:has_decimal] = true if @options[:maximumFractionDigits] > 0
            else
              info[:fractional_digits] = [info[:fractional_digits], @options[:maximumFractionDigits]].min
            end

            # If maximum is 0, don't show decimals at all
            if @options[:maximumFractionDigits] == 0
              info[:fractional_digits] = 0
              info[:required_fractional_digits] = 0
              info[:has_decimal] = false
            end
          end

          info
        end

        # Format integer part with proper grouping based on pattern
        private def format_integer_with_grouping(integer_part, pattern_info)
          return integer_part unless pattern_info[:has_grouping]

          # Split integer into groups of 3 digits from right
          digit_groups = split_into_groups(integer_part)

          # Apply grouping separators
          digit_groups.join(@formats.group_symbol)
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
        private def format_non_digit_token(token, decimal_value)
          case token
          when Foxtail::CLDR::PatternParser::Number::CurrencyToken
            format_currency_token(token, decimal_value)
          when Foxtail::CLDR::PatternParser::Number::PercentToken
            @formats.percent_sign
          when Foxtail::CLDR::PatternParser::Number::PerMilleToken
            "‰"
          when Foxtail::CLDR::PatternParser::Number::ExponentToken
            format_exponent_token(token, decimal_value)
          when Foxtail::CLDR::PatternParser::Number::LiteralToken
            token.value
          when Foxtail::CLDR::PatternParser::Number::QuotedToken
            token.literal_text
          when Foxtail::CLDR::PatternParser::Number::PlusToken
            "+"
          when Foxtail::CLDR::PatternParser::Number::MinusToken
            @formats.minus_sign
          else
            ""
          end
        end

        # Format currency token
        private def format_currency_token(token, _decimal_value)
          currency_code = @options[:currency] || "USD"

          case token.currency_type
          when :symbol
            @currencies.currency_symbol(currency_code)
          when :code
            currency_code
          when :name
            # Use original value for plural determination (not transformed value)
            original_value = @original_value
            plural_rules = Foxtail::CLDR::Repository::PluralRules.new(@formats.locale)
            plural_category = plural_rules.select(original_value)
            @currencies.currency_name(currency_code, plural_category)
          end
        end

        # Format exponent token for scientific notation (deprecated - use format_exponent_token_with_value)
        private def format_exponent_token(token, decimal_value)
          return "E0" if decimal_value.zero?

          # Calculate exponent
          abs_value = decimal_value.abs
          exponent = bigdecimal_log10(abs_value).floor

          # Format exponent with required digits
          exponent_str = exponent.abs.to_s.rjust(token.exponent_digits, "0")
          exponent_str = "#{@formats.minus_sign}#{exponent_str}" if exponent.negative?
          exponent_str = "+#{exponent_str}" if exponent.positive? && token.show_exponent_sign?

          "E#{exponent_str}"
        end

        # Format exponent token with pre-calculated exponent value
        private def format_exponent_token_with_value(token, exponent)
          return "E0" if exponent.zero?

          # Format exponent with required digits
          exponent_str = exponent.abs.to_s.rjust(token.exponent_digits, "0")
          exponent_str = "#{@formats.minus_sign}#{exponent_str}" if exponent.negative?
          exponent_str = "+#{exponent_str}" if exponent.positive? && token.show_exponent_sign?

          "E#{exponent_str}"
        end

        # Normalize number for scientific notation (mantissa between 1-10)
        private def normalize_for_scientific(decimal_value, _pattern_info)
          return {mantissa: BigDecimal(0), exponent: 0} if decimal_value.zero?

          abs_value = decimal_value.abs

          # Calculate exponent to normalize mantissa between 1-10
          exponent = bigdecimal_log10(abs_value).floor

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
          raw_exponent = bigdecimal_log10(abs_value).floor

          # Adjust exponent to be multiple of 3
          # Engineering notation uses exponents: ..., -6, -3, 0, 3, 6, 9, ...
          engineering_exponent = (raw_exponent / 3.0).floor * 3

          # Calculate mantissa by dividing by 10^engineering_exponent
          mantissa = abs_value / (BigDecimal(10)**engineering_exponent)

          # Preserve sign
          mantissa = -mantissa if decimal_value.negative?

          {mantissa:, exponent: engineering_exponent}
        end

        # Combine scientific pattern with style-specific symbols
        private def combine_pattern_with_style(base_pattern, style)
          case style
          when "currency"
            currency_pattern = @formats.currency_pattern
            combine_patterns_using_tokens(base_pattern, currency_pattern)
          when "percent"
            percent_pattern = @formats.percent_pattern
            combine_patterns_using_tokens(base_pattern, percent_pattern)
          else
            # For units, decimal, and default cases, use base pattern as-is
            # Unit symbol will be added in format_with_pattern for unit style
            base_pattern
          end
        end

        private def combine_patterns_using_tokens(number_pattern, style_pattern)
          parser = Foxtail::CLDR::PatternParser::Number.new

          # Parse both patterns into tokens
          number_tokens = parser.parse(number_pattern)
          style_tokens = parser.parse(style_pattern)

          # Find where to insert the number tokens
          combined_tokens = []
          number_tokens_inserted = false

          style_tokens.each do |token|
            case token
            when Foxtail::CLDR::PatternParser::Number::DigitToken,
                 Foxtail::CLDR::PatternParser::Number::DecimalToken,
                 Foxtail::CLDR::PatternParser::Number::GroupToken,
                 Foxtail::CLDR::PatternParser::Number::ExponentToken

              # Replace with number pattern tokens (only once)
              unless number_tokens_inserted
                combined_tokens.concat(number_tokens)
                number_tokens_inserted = true
              end
            else
              # Keep non-number tokens
              combined_tokens << token
            end
          end

          # Convert tokens back to pattern string
          combined_tokens.map(&:to_s).join
        end

        # Format number using compact notation based on CLDR data
        private def format_compact_number(decimal_value, original_was_negative)
          style = @options[:style] || "decimal"

          # Handle zero value with style - use proper pattern formatting
          if decimal_value.zero?
            formatted_number = "0"
            return apply_style_to_compact_result(formatted_number, style)
          end

          compact_display = @options[:compactDisplay] || "short"
          compact_info = find_compact_pattern(decimal_value, compact_display)

          if compact_info.nil?
            # No compacting - format with appropriate decimal places and apply style

            if decimal_value.abs < 1 && decimal_value.abs > 0
              # For small decimal values, use CLDR pattern with proper locale symbols
              significant_digits = @formats.compact_decimal_significant_digits
              # Create a pattern with appropriate decimal places (e.g., "0.##" for maximum 2 digits)
              decimal_pattern = "0.#{"#" * significant_digits[:maximum]}"
              formatted = format_decimal_with_locale_symbols(decimal_value.abs, decimal_pattern, significant_digits[:maximum])
            else
              # For integer values, round first then format
              # Apply rounding to original signed value for correct result
              original_value = original_was_negative ? -decimal_value : decimal_value
              rounded_value = original_value.round
              formatted = rounded_value.abs.to_s
              if rounded_value.negative?
                formatted = @formats.minus_sign + formatted
              end
              # Apply style to the formatted number
              return apply_style_to_compact_result(formatted, style)
            end

            # Apply sign and style
            if original_was_negative
              formatted = @formats.minus_sign + formatted
            end
            return apply_style_to_compact_result(formatted, style)
          end

          # Apply the pattern (handles positive value)
          formatted_number = apply_compact_pattern(decimal_value.abs, compact_info)

          # Preserve original sign using passed option
          if original_was_negative
            formatted_number = @formats.minus_sign + formatted_number
          end

          # Apply style to compact result
          apply_style_to_compact_result(formatted_number, style)
        end

        # Find the appropriate compact pattern from CLDR data
        private def find_compact_pattern(decimal_value, compact_display)
          abs_value = decimal_value.abs
          patterns = @formats.compact_patterns(compact_display)

          return nil if patterns.empty?

          # Find the best matching pattern by magnitude
          best_magnitude = nil

          # Sort magnitudes in ascending order and find the highest one that the value reaches
          magnitudes = patterns.keys.map {|k| Integer(k, 10) }
          magnitudes.sort!
          magnitudes.each do |magnitude|
            # Value must be >= magnitude to use this pattern
            next if abs_value < magnitude

            best_magnitude = magnitude.to_s
            # Continue to find the highest applicable magnitude
          end

          return nil unless best_magnitude

          pattern = @formats.compact_pattern(best_magnitude, compact_display, "other")
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
          # NOTE: decimal_value should already be positive (abs applied by caller)
          scaled_value = decimal_value / BigDecimal(compact_info[:divisor])
          pattern = compact_info[:pattern]

          # Parse pattern into tokens
          parser = Foxtail::CLDR::PatternParser::Number.new
          tokens = parser.parse(pattern)

          # Count digit tokens to determine how many digits to show
          digit_tokens = tokens.select {|t| t.is_a?(Foxtail::CLDR::PatternParser::Number::DigitToken) }
          zero_count = digit_tokens.sum(&:digit_count)

          # Format number based on the pattern's zero count
          formatted_number = if zero_count == 1
                               # Pattern like "0K" - show 1 significant digit with decimal if needed
                               format_compact_single_digit(scaled_value)
                             else
                               # Pattern like "00K", "000K" - show integer with appropriate digits
                               format_compact_multiple_digits(scaled_value, zero_count)
                             end

          # Replace digit tokens with formatted number
          apply_compact_pattern_using_tokens(tokens, formatted_number)
        end

        private def apply_compact_pattern_using_tokens(tokens, formatted_number)
          result_parts = []
          number_inserted = false

          tokens.each do |token|
            case token
            when Foxtail::CLDR::PatternParser::Number::DigitToken
              # Replace digit tokens with formatted number (only once)
              unless number_inserted
                result_parts << formatted_number
                number_inserted = true
              end
            when Foxtail::CLDR::PatternParser::Number::LiteralToken,
                 Foxtail::CLDR::PatternParser::Number::QuotedToken

              # Keep literal tokens (including unit symbols like "K", "万")
              result_parts << if token.is_a?(Foxtail::CLDR::PatternParser::Number::QuotedToken)
                                token.literal_text
                              else
                                token.to_s
                              end
            else
              # Keep other tokens as-is
              result_parts << token.to_s
            end
          end

          result_parts.join
        end

        # Format scaled value for single-digit compact patterns (e.g., "0K")
        private def format_compact_single_digit(scaled_value)
          if scaled_value >= 10
            scaled_value.round.to_s
          elsif scaled_value.round(1) == scaled_value.round(0)
            scaled_value.round(0).to_s
          else
            formatted = scaled_value.round(1).to_s("F")
            # Replace English decimal separator with locale-specific one
            formatted.gsub(".", @formats.decimal_symbol)
          end
        end

        # Format scaled value for multi-digit compact patterns (e.g., "00K", "000K")
        private def format_compact_multiple_digits(scaled_value, _zero_count)
          # For multi-digit patterns, show integer value with locale formatting
          integer_value = scaled_value.round(0)

          if integer_value >= 1000
            # Apply locale-specific grouping for large numbers
            format_integer_with_locale_grouping(integer_value.to_s)
          else
            integer_value.to_s
          end
        end

        # Helper method to apply locale grouping to integer strings
        private def format_integer_with_locale_grouping(integer_str)
          # Split into groups of 3 digits from right to left
          groups = integer_str.reverse.scan(/.{1,3}/).map(&:reverse)
          groups.reverse!
          groups.join(@formats.group_symbol)
        end

        # Find the base divisor for a unit by finding the smallest magnitude with the same unit symbol
        private def find_base_divisor_for_unit(target_pattern, all_patterns)
          # Extract unit symbol from target pattern using token parsing
          unit_symbol = extract_unit_symbol_from_pattern(target_pattern)

          # If there's no unit symbol (pattern is just "0"), this means no compacting
          return 1 if unit_symbol.empty?

          # Find all patterns with the same unit symbol and get their magnitudes
          same_unit_magnitudes = []
          all_patterns.each do |magnitude_str, count_patterns|
            count_patterns.each_value do |pattern|
              pattern_unit = extract_unit_symbol_from_pattern(pattern)
              if pattern_unit == unit_symbol
                same_unit_magnitudes << Integer(magnitude_str, 10)
              end
            end
          end

          # Return the smallest magnitude for this unit (that's the base divisor)
          same_unit_magnitudes.min || 1
        end

        private def extract_unit_symbol_from_pattern(pattern)
          parser = Foxtail::CLDR::PatternParser::Number.new
          tokens = parser.parse(pattern)

          # Get all non-digit tokens and join them to form the unit symbol
          unit_tokens = tokens.reject {|token|
            token.is_a?(Foxtail::CLDR::PatternParser::Number::DigitToken)
          }

          unit_tokens.map {|token|
            case token
            when Foxtail::CLDR::PatternParser::Number::QuotedToken
              token.literal_text
            else
              token.to_s
            end
          }.join
        end

        # Apply style formatting to compact notation result
        private def apply_style_to_compact_result(formatted_number, style)
          case style
          when "currency"
            currency_code = @options[:currency] || "USD"
            symbol = @currencies.currency_symbol(currency_code)
            currency_pattern = @formats.currency_pattern
            apply_style_pattern_to_compact_result(formatted_number, currency_pattern, symbol)
          when "percent"
            percent_pattern = @formats.percent_pattern
            apply_style_pattern_to_compact_result(formatted_number, percent_pattern, "%")
          when "unit"
            unit = @options[:unit] || "meter"
            unit_display = @options[:unitDisplay] || "short"
            unit_pattern = @units.unit_pattern(unit, unit_display.to_sym, :other)

            if unit_pattern
              unit_pattern.gsub("{0}", formatted_number)
            else
              "#{formatted_number} #{unit}"
            end
          else
            formatted_number
          end
        end

        # Format decimal number with proper locale symbols for compact notation
        private def format_decimal_with_locale_symbols(decimal_value, _pattern, max_digits)
          # Use Ruby's sprintf-style formatting with 'g' to get the right precision
          format_spec = "%.#{max_digits}g"
          formatted = format_spec % decimal_value

          # Replace the English '.' with the locale's decimal symbol
          formatted.gsub(".", @formats.decimal_symbol)
        end

        private def apply_style_pattern_to_compact_result(formatted_number, pattern, style_symbol)
          parser = Foxtail::CLDR::PatternParser::Number.new
          tokens = parser.parse(pattern)

          # Check if formatted number is negative and extract clean number
          is_negative = formatted_number.start_with?(@formats.minus_sign)
          clean_number = is_negative ? formatted_number[@formats.minus_sign.length..] : formatted_number

          # Apply locale-specific grouping to clean number if it's a large integer
          # Only apply grouping for percent style in compact notation (Node.js behavior)
          if style_symbol == "%" && clean_number.match?(/^\d{4,}$/) # 4+ digit integers
            clean_number = format_integer_with_locale_grouping(clean_number)
          end

          # Parse pattern to identify prefix and suffix tokens similar to existing logic
          pattern_info = analyze_pattern_structure(tokens)

          result = ""

          # Handle negative sign positioning for currency and percent
          if is_negative
            # Check if there's a space or other non-currency/percent tokens between symbol and digits
            has_separator_in_prefix =
              pattern_info[:prefix_tokens].size > 1 &&
              pattern_info[:prefix_tokens].any? {|t|
                !t.is_a?(Foxtail::CLDR::PatternParser::Number::CurrencyToken) &&
                  !t.is_a?(Foxtail::CLDR::PatternParser::Number::PercentToken)
              }

            if has_separator_in_prefix
              pattern_info[:prefix_tokens].each do |token|
                result += format_compact_non_digit_token(token, style_symbol)
              end
              result += @formats.minus_sign + clean_number
            else
              result += @formats.minus_sign
              pattern_info[:prefix_tokens].each do |token|
                result += format_compact_non_digit_token(token, style_symbol)
              end
              result += clean_number
            end
          else
            # Normal positive case - process prefix tokens then number
            pattern_info[:prefix_tokens].each do |token|
              result += format_compact_non_digit_token(token, style_symbol)
            end
            result += clean_number
          end

          # Add suffix tokens
          pattern_info[:suffix_tokens].each do |token|
            result += format_compact_non_digit_token(token, style_symbol)
          end

          result
        end

        # Helper method to format non-digit tokens for compact results
        private def format_compact_non_digit_token(token, style_symbol)
          case token
          when Foxtail::CLDR::PatternParser::Number::CurrencyToken,
               Foxtail::CLDR::PatternParser::Number::PercentToken

            style_symbol
          when Foxtail::CLDR::PatternParser::Number::LiteralToken,
               Foxtail::CLDR::PatternParser::Number::QuotedToken

            token.is_a?(Foxtail::CLDR::PatternParser::Number::QuotedToken) ? token.literal_text : token.to_s
          else
            ""
          end
        end

        # Calculate base-10 logarithm of BigDecimal value
        # Check if value is a special value (Infinity, -Infinity, NaN)
        private def special_value?(value)
          return false unless value.is_a?(Numeric)

          # Check for infinity (available on Float and BigDecimal)
          return true if value.respond_to?(:infinite?) && value.infinite?

          # Check for NaN (available on Float and BigDecimal)
          return true if value.respond_to?(:nan?) && value.nan?

          false
        end

        # Format special values (Infinity, -Infinity, NaN)
        private def format_special_value(value)
          # Determine the base symbol (without embedding minus for negative infinity)
          if value.nan?
            symbol = "NaN"
          elsif value.infinite?
            symbol = "∞" # Let pattern handle minus sign for negative infinity
          else
            raise ArgumentError, "Expected special value (Infinity, -Infinity, or NaN), got: #{value.inspect}"
          end

          # Use the same pattern-based approach as regular formatting
          pattern = determine_pattern
          parser = Foxtail::CLDR::PatternParser::Number.new
          tokens = parser.parse(pattern)

          # Split positive and negative patterns if present
          pattern_tokens, has_separator =
            case tokens
            in [*positive, Foxtail::CLDR::PatternParser::Number::PatternSeparatorToken, *negative]
              # Use negative pattern for negative infinity, positive for others
              [value.infinite? == -1 ? negative : positive, true]
            in _
              [tokens, false]
            end

          # Build the result using tokens (similar to build_formatted_string)
          result = ""

          # Handle minus sign for negative infinity (when no separate negative pattern)
          original_was_negative = value.infinite? == -1 && !has_separator

          # Process prefix tokens (currency symbols, literals, etc. before the number)
          if original_was_negative
            # Add minus sign first for negative values (like regular formatting)
            result += @formats.minus_sign
          end

          pattern_tokens.each do |token|
            break if token.is_a?(Foxtail::CLDR::PatternParser::Number::DigitToken) ||
                     token.is_a?(Foxtail::CLDR::PatternParser::Number::GroupToken) ||
                     token.is_a?(Foxtail::CLDR::PatternParser::Number::DecimalToken)

            # Skip exponent tokens for special values - they don't have meaningful exponents
            next if token.is_a?(Foxtail::CLDR::PatternParser::Number::ExponentToken)

            result += format_non_digit_token(token, value)
          end

          # Add the special value symbol
          result += symbol

          # Process suffix tokens (percent signs, currency symbols at the end, etc.)
          found_digit_section = false
          pattern_tokens.each do |token|
            if token.is_a?(Foxtail::CLDR::PatternParser::Number::DigitToken) ||
               token.is_a?(Foxtail::CLDR::PatternParser::Number::GroupToken) ||
               token.is_a?(Foxtail::CLDR::PatternParser::Number::DecimalToken)

              found_digit_section = true
              next
            end

            # Only process tokens after the digit section
            next unless found_digit_section
            # Skip exponent tokens for special values
            next if token.is_a?(Foxtail::CLDR::PatternParser::Number::ExponentToken)

            result += format_non_digit_token(token, value)
          end

          # Apply unit pattern for unit style (same as regular formatting)
          style = @options[:style] || "decimal"
          if style == "unit"
            unit = @options[:unit] || "meter"
            unit_display = @options[:unitDisplay] || "short"
            unit_pattern = @units.unit_pattern(unit, unit_display.to_sym, :other)

            if unit_pattern
              # Replace {0} placeholder with the formatted result
              result = unit_pattern.gsub("{0}", result)
            else
              # Fallback: append unit name
              result += " #{unit}"
            end
          end

          result
        end

        private def bigdecimal_log10(value)
          return BigDecimal("-Infinity") if value <= 0

          # Use BigMath.log with precision of 10 digits
          # log10(x) = log(x) / log(10)
          BigMath.log(value, 10) / BigMath.log(BigDecimal(10), 10)
        end
      end
    end
  end
end
