# frozen_string_literal: true

module Foxtail
  module CLDR
    module PatternParser
      # Parses CLDR number patterns into tokens for formatting
      #
      # This class is responsible for tokenizing CLDR number patterns like:
      # - "#,##0.00" (basic decimal)
      # - "¤#,##0.00" (currency)
      # - "#,##0.00%;(#,##0.00%)" (positive/negative patterns)
      # - "#.##E0" (scientific notation)
      #
      # The parsing follows CLDR number pattern specifications and produces
      # tokens that can be used by NumberFormatter for actual formatting.
      #
      # @example Basic usage
      #   parser = Number.new
      #   tokens = parser.parse("#,##0.00")
      #   # => [DigitToken, GroupToken, DigitToken, DecimalToken, DigitToken]
      class Number
        # Base class for all pattern tokens
        class Token
          attr_reader :value

          def initialize(value)
            @value = value
          end

          def ==(other)
            other.is_a?(self.class) && other.value == value
          end

          def to_s
            value
          end
        end

        # Represents digit placeholders (0, #)
        class DigitToken < Token
          def digit_count
            value.length
          end

          def required?
            value[0] == "0"
          end

          def optional?
            value[0] == "#"
          end
        end

        # Represents currency symbol (¤)
        class CurrencyToken < Token
          def currency_type
            case value.length
            when 2 then :code       # ¤¤ -> USD
            when 3 then :name       # ¤¤¤ -> US Dollar
            else :symbol            # ¤ -> $ (default for 1 or other lengths)
            end
          end
        end

        # Represents percent symbol (%)
        class PercentToken < Token
        end

        # Represents per mille symbol (‰)
        class PerMilleToken < Token
        end

        # Represents decimal separator (.)
        class DecimalToken < Token
        end

        # Represents grouping separator (,)
        class GroupToken < Token
        end

        # Represents plus sign (+)
        class PlusToken < Token
        end

        # Represents minus sign (-)
        class MinusToken < Token
        end

        # Represents scientific notation exponent (E)
        class ExponentToken < Token
          def exponent_digits
            # Count the digits after E (e.g., "E0" -> 1, "E00" -> 2, "E+000" -> 3)
            match = value.match(/E\+?(0+)$/i)
            return 1 unless match

            match.captures.first.length
          end

          def show_exponent_sign?
            value.include?("+")
          end
        end

        # Represents literal text
        class LiteralToken < Token
        end

        # Represents quoted literal text
        class QuotedToken < Token
          def literal_text
            # Remove surrounding quotes and handle escaped quotes
            value[1..-2].gsub("''", "'")
          end
        end

        # Special token to separate positive and negative patterns
        class PatternSeparatorToken < Token
        end

        # Parse a CLDR number pattern into tokens
        #
        # @param pattern [String] CLDR pattern to parse
        # @return [Array<Token>] Array of parsed tokens
        def parse(pattern)
          return [] if pattern.nil? || pattern.empty?

          tokens = []
          i = 0

          while i < pattern.length
            matched = false

            # Try to match quoted literals first
            if pattern[i] == "'"
              quote_match = match_quoted_literal(pattern, i)
              if quote_match
                tokens << QuotedToken.new(quote_match[:text])
                i += quote_match[:length]
                matched = true
              end
            end

            unless matched
              # Pattern separator (semicolon)
              if pattern[i] == ";"
                tokens << PatternSeparatorToken.new(";")
                i += 1
                matched = true
              # Currency symbols
              elsif pattern[i] == "¤"
                currency_match = match_currency_symbol(pattern, i)
                tokens << CurrencyToken.new(currency_match[:text])
                i += currency_match[:length]
                matched = true
              # Percent symbol
              elsif pattern[i] == "%"
                tokens << PercentToken.new("%")
                i += 1
                matched = true
              # Per mille symbol
              elsif pattern[i] == "‰"
                tokens << PerMilleToken.new("‰")
                i += 1
                matched = true
              # Decimal separator
              elsif pattern[i] == "."
                tokens << DecimalToken.new(".")
                i += 1
                matched = true
              # Grouping separator
              elsif pattern[i] == ","
                tokens << GroupToken.new(",")
                i += 1
                matched = true
              # Plus sign
              elsif pattern[i] == "+"
                tokens << PlusToken.new("+")
                i += 1
                matched = true
              # Minus sign
              elsif pattern[i] == "-"
                tokens << MinusToken.new("-")
                i += 1
                matched = true
              # Scientific notation exponent
              elsif pattern[i].casecmp("E").zero?
                exponent_match = match_exponent(pattern, i)
                if exponent_match
                  tokens << ExponentToken.new(exponent_match[:text])
                  i += exponent_match[:length]
                  matched = true
                end
              # Digit patterns (0, #) - match sequences of same character
              elsif pattern[i] == "0" || pattern[i] == "#"
                digit_match = match_digit_sequence(pattern, i)
                tokens << DigitToken.new(digit_match[:text])
                i += digit_match[:length]
                matched = true
              end
            end

            # If no pattern matched, treat as literal character
            next if matched

            # Combine consecutive literal characters
            if tokens.last.is_a?(LiteralToken)
              tokens.last.instance_variable_set(:@value, tokens.last.value + pattern[i])
            else
              tokens << LiteralToken.new(pattern[i])
            end
            i += 1
          end

          # Validate the parsed tokens
          validate_tokens(tokens, pattern)

          tokens
        end

        # Validate parsed tokens for logical consistency
        private def validate_tokens(tokens, original_pattern)
          has_percent = tokens.any?(PercentToken)
          has_permille = tokens.any?(PerMilleToken)

          # Error on conflicting multiplier symbols
          return unless has_percent && has_permille

          raise ArgumentError, "Pattern cannot contain both percent (%) and permille (‰) symbols: #{original_pattern}"
        end

        private def match_quoted_literal(pattern, start_pos)
          return nil unless pattern[start_pos] == "'"

          end_pos = start_pos + 1

          while end_pos < pattern.length
            char = pattern[end_pos]

            if char == "'"
              # Check if this is an escaped quote (two consecutive quotes)
              if end_pos + 1 < pattern.length && pattern[end_pos + 1] == "'"
                # Skip the escaped quote pair
                end_pos += 2
                next
              else
                # Found closing quote
                return {
                  text: pattern[start_pos..end_pos],
                  length: end_pos - start_pos + 1
                }
              end
            end

            end_pos += 1
          end

          # Unclosed quote - treat as literal
          nil
        end

        private def match_currency_symbol(pattern, start_pos)
          count = 0
          pos = start_pos

          while pos < pattern.length && pattern[pos] == "¤"
            count += 1
            pos += 1
            # Limit to 3 currency symbols max
            break if count >= 3
          end

          {
            text: "¤" * count,
            length: count
          }
        end

        private def match_exponent(pattern, start_pos)
          return nil if pattern[start_pos].casecmp("E").nonzero?

          pos = start_pos + 1
          exponent_text = pattern[start_pos] # Preserve original case

          # Check for optional + sign
          if pos < pattern.length && pattern[pos] == "+"
            exponent_text += "+"
            pos += 1
          end

          # Must have at least one digit after E
          return nil unless pos < pattern.length && pattern[pos] == "0"

          # Count consecutive zeros
          while pos < pattern.length && pattern[pos] == "0"
            exponent_text += "0"
            pos += 1
          end

          {
            text: exponent_text,
            length: pos - start_pos
          }
        end

        private def match_digit_sequence(pattern, start_pos)
          digit_char = pattern[start_pos]
          count = 0
          pos = start_pos

          # Match only consecutive identical digit characters
          while pos < pattern.length && pattern[pos] == digit_char
            count += 1
            pos += 1
          end

          {
            text: digit_char * count,
            length: count
          }
        end
      end
    end
  end
end
