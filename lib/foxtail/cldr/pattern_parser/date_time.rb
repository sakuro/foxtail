# frozen_string_literal: true

module Foxtail
  module CLDR
    module PatternParser
      # Formal CLDR date/time pattern parser
      #
      # Parses CLDR date/time format patterns according to UTS #35 specification:
      # https://unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns
      #
      # @example
      #   parser = DateTime.new
      #   tokens = parser.parse("EEEE, MMMM d, yyyy")
      #   # => [
      #   #      FieldToken.new("EEEE"),
      #   #      LiteralToken.new(", "),
      #   #      FieldToken.new("MMMM"),
      #   #      LiteralToken.new(" "),
      #   #      FieldToken.new("d"),
      #   #      LiteralToken.new(", "),
      #   #      FieldToken.new("yyyy")
      #   #    ]
      class DateTime
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

        # Represents a CLDR field pattern (yyyy, MM, dd, etc.)
        class FieldToken < Token
          def field_type
            case value[0]
            when "y", "Y" then :year
            when "M" then :month
            when "d", "D" then :day
            when "E" then :weekday
            when "H", "h", "K", "k" then :hour
            when "m" then :minute
            when "s", "S" then :second
            when "a" then :am_pm
            when "z", "Z", "X", "x" then :timezone
            else :unknown
            end
          end

          def field_length
            value.length
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

        # CLDR pattern field specifications, ordered by length (longest first)
        FIELD_PATTERNS = %w[
          EEEE
          EEE
          yyyy
          MMMM
          MMM
          MM
          dd
          HH
          hh
          mm
          ss
          yy
          M
          d
          H
          h
          y
          a
        ].freeze

        private_constant :FIELD_PATTERNS

        # Parse a CLDR date/time pattern into tokens
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
              # Try to match field patterns (longest first)
              FIELD_PATTERNS.each do |field_pattern|
                next unless pattern[i, field_pattern.length] == field_pattern
                # For single-letter tokens, check if it's part of a word
                if field_pattern.length == 1 && part_of_word?(pattern, i, field_pattern)
                  next
                end

                tokens << FieldToken.new(field_pattern)
                i += field_pattern.length
                matched = true
                break
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

          tokens
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

        # Check if a single-letter token is part of a literal word/text
        private def part_of_word?(pattern, position, token)
          return false if token.length > 1

          prev_char = position > 0 ? pattern[position - 1] : nil
          next_char = position + 1 < pattern.length ? pattern[position + 1] : nil

          # CLDR pattern letters that are valid in field contexts
          cldr_letters = /[EMydhHmsaYDKkzZXx]/

          # If surrounded by non-CLDR ASCII letters, it's part of literal text
          (prev_char&.match?(/[a-zA-Z]/) && !prev_char.match?(cldr_letters)) ||
          (next_char&.match?(/[a-zA-Z]/) && !next_char.match?(cldr_letters))
        end
      end
    end
  end
end
