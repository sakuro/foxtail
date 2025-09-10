# frozen_string_literal: true

require "locale"

module Foxtail
  module CLDR
    # CLDR number formatting data loader and processor
    # Provides locale-specific number formatting information
    #
    # Based on Unicode CLDR specifications:
    # - https://unicode.org/reports/tr35/tr35-numbers.html
    # - Supports decimal symbols, grouping, patterns for decimal/percent/currency
    #
    # Example usage:
    #   formats = NumberFormats.new("en")
    #   formats.decimal_symbol      # => "."
    #   formats.group_symbol        # => ","
    #   formats.decimal_pattern     # => "#,##0.###"
    #   formats.percent_pattern     # => "#,##0%"
    class NumberFormats < Base
      def initialize(locale)
        super
        @data = load_data["number_formats"] || {}
        @currency_fractions = load_data["currency_fractions"] || {}
      end

      # Get decimal symbol
      def decimal_symbol
        @data.dig("symbols", "decimal") || "."
      end

      # Get grouping symbol
      def group_symbol
        @data.dig("symbols", "group") || ","
      end

      # Get minus sign
      def minus_sign
        @data.dig("symbols", "minus_sign") || "-"
      end

      # Get plus sign
      def plus_sign
        @data.dig("symbols", "plus_sign") || "+"
      end

      # Get percent sign
      def percent_sign
        @data.dig("symbols", "percent_sign") || "%"
      end

      # Get per mille sign
      def per_mille_sign
        @data.dig("symbols", "per_mille") || "‰"
      end

      # Get infinity symbol
      def infinity_symbol
        @data.dig("symbols", "infinity") || "∞"
      end

      # Get NaN symbol
      def nan_symbol
        @data.dig("symbols", "nan") || "NaN"
      end

      # Get decimal format pattern
      def decimal_pattern(style="standard")
        @data.dig("decimal_formats", style) || default_decimal_pattern
      end

      # Get percent format pattern
      def percent_pattern(style="standard")
        @data.dig("percent_formats", style) || default_percent_pattern
      end

      # Get currency format pattern
      def currency_pattern(style="standard")
        @data.dig("currency_formats", style) || default_currency_pattern(style)
      end

      # Get scientific format pattern
      def scientific_pattern(style="standard")
        @data.dig("scientific_formats", style) || default_scientific_pattern
      end

      # Get currency symbol for a given currency code
      def currency_symbol(currency_code)
        @data.dig("currencies", currency_code, "symbol") || currency_code
      end

      # Get currency display name for a given currency code and plural form
      def currency_display_name(currency_code, count="other")
        @data.dig("currencies", currency_code, "display_names", count) ||
          @data.dig("currencies", currency_code, "display_names", "other") ||
          currency_code
      end

      # Get decimal digits for a currency (defaults to 2 if not found)
      def currency_digits(currency_code)
        @currency_fractions.dig(currency_code, "digits") || 2
      end

      # Get cash digits for a currency (falls back to regular digits)
      def currency_cash_digits(currency_code)
        @currency_fractions.dig(currency_code, "cash_digits") || currency_digits(currency_code)
      end

      # Get all available currency codes
      def currency_codes
        @data["currencies"]&.keys || []
      end

      private def default_decimal_pattern
        "#,##0.###"
      end

      private def default_percent_pattern
        "#,##0%"
      end

      private def default_currency_pattern(style)
        case style
        when "accounting" then "¤#,##0.00;(¤#,##0.00)"
        else "¤#,##0.00"
        end
      end

      private def default_scientific_pattern
        "#E0"
      end
    end
  end
end
