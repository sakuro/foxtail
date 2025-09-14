# frozen_string_literal: true

require "bigdecimal"
require "locale"

module Foxtail
  module CLDR
    module Repository
      # ICU-compliant plural rules processor
      # Evaluates CLDR plural rule expressions to determine plural categories
      #
      # Based on Unicode CLDR specifications:
      # - https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules
      # - Supports all standard plural categories: zero, one, two, few, many, other
      #
      # Example usage:
      #   rules = PluralRules.new("en")
      #   rules.select(1)     # => "one"
      #   rules.select(2)     # => "other"
      #   rules.select(0)     # => "other"
      class PluralRules < Base
        def initialize(locale)
          super
          @resolver = Resolver.new(@locale)
        end

        # Select appropriate plural category for the given number
        # @param number [Numeric] the number to evaluate
        # @return [String] plural category ("zero", "one", "two", "few", "many", "other")
        def select(number)
          # Extract operands according to CLDR specification
          operands = extract_operands(number)

          # Test each rule condition in priority order
          %w[zero one two few many].each do |category|
            condition = @resolver.resolve("plural_rules.#{category}", "plural_rules")
            next if condition.nil? || condition.empty?

            if evaluate_condition(condition, operands)
              return category
            end
          end

          # Default fallback
          "other"
        end

        # Extract CLDR operands from number
        # According to CLDR spec:
        # - n: absolute value of the source number
        # - i: integer digits of n
        # - v: number of visible fraction digits in n, with trailing zeros counted
        # - w: number of visible fraction digits in n, without trailing zeros
        # - f: visible fractional digits in n, with trailing zeros
        # - t: visible fractional digits in n, without trailing zeros
        private def extract_operands(number)
          n = number.abs

          if number.is_a?(Float) || number.is_a?(BigDecimal)
            # Handle floating point and BigDecimal numbers
            # Convert to string in standard format (not scientific notation)
            str = number.is_a?(BigDecimal) ? number.to_s("F") : number.to_s

            if str.include?(".")
              integer_part, fraction_part = str.split(".")
              i = Integer(integer_part, 10).abs

              # CLDR-compliant approach: v counts all visible fraction digits
              # including trailing zeros, as per CLDR specification
              v = fraction_part.length

              # Remove trailing zeros for w and t
              visible_fraction = fraction_part.sub(/0+$/, "")
              w = visible_fraction.length # number of visible fraction digits (without trailing zeros)

              f = Integer(fraction_part, 10) # fraction digits as integer
              t = visible_fraction.empty? ? 0 : Integer(visible_fraction, 10) # visible fraction as integer
            else
              i = Integer(n)
              v = w = f = t = 0
            end
          else
            # Handle integer numbers
            i = Integer(n)
            v = w = f = t = 0
          end

          {
            n:,
            i:,
            v:,
            w:,
            f:,
            t:
          }
        end

        # Evaluate CLDR plural rule condition
        # Supports standard CLDR operators: =, !=, and ranges (e.g., 2..4)
        private def evaluate_condition(condition, operands)
          # Simple parser for CLDR plural rule expressions
          # This is a basic implementation - could be extended for more complex rules

          # Split by 'or' first
          or_parts = condition.split(" or ")

          or_parts.any? do |or_part|
            # Split by 'and'
            and_parts = or_part.strip.split(" and ")

            and_parts.all? do |and_part|
              evaluate_simple_condition(and_part.strip, operands)
            end
          end
        end

        # Evaluate simple condition like "i = 1" or "n % 10 = 2..4"
        private def evaluate_simple_condition(condition, operands)
          # Parse condition pattern
          if condition =~ /^(\w+)(?:\s*%\s*(\d+))?\s*(=|!=)\s*(.+)$/
            operand = $1
            modulo = $2 ? Integer($2, 10) : nil
            operator = $3
            value_expr = $4

            # Get operand value
            operand_value = operands[operand.to_sym]
            return false unless operand_value

            # Apply modulo if present
            operand_value %= modulo if modulo

            # Parse value expression (can be single number, comma-separated, or range)
            expected_values = parse_value_expression(value_expr)

            case operator
            when "="
              expected_values.include?(operand_value)
            when "!="
              !expected_values.include?(operand_value)
            else
              false
            end
          else
            # Unknown condition format
            false
          end
        end

        # Parse value expression like "1", "0,1", "2..4", "11..99"
        private def parse_value_expression(expr)
          values = []

          expr.split(",").each do |part|
            part = part.strip

            if part.include?("..")
              # Range like "2..4"
              start_val, end_val = part.split("..").map {|val| Integer(val, 10) }
              values.concat((start_val..end_val).to_a)
            else
              # Single value
              values << Integer(part, 10)
            end
          end

          values
        end
      end
    end
  end
end
