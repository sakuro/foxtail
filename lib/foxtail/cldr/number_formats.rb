# frozen_string_literal: true

require "locale"
require_relative "base"
require_relative "resolver"

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
        @resolver = Resolver.new(@locale.to_simple.to_s)
      end

      # Get decimal symbol
      def decimal_symbol
        @resolver.resolve("number_formats.symbols.decimal", "number_formats") || "."
      end

      # Get grouping symbol
      def group_symbol
        @resolver.resolve("number_formats.symbols.group", "number_formats") || ","
      end

      # Get minus sign
      def minus_sign
        @resolver.resolve("number_formats.symbols.minus_sign", "number_formats") || "-"
      end

      # Get plus sign
      def plus_sign
        @resolver.resolve("number_formats.symbols.plus_sign", "number_formats") || "+"
      end

      # Get percent sign
      def percent_sign
        @resolver.resolve("number_formats.symbols.percent_sign", "number_formats") || "%"
      end

      # Get per mille sign
      def per_mille_sign
        @resolver.resolve("number_formats.symbols.per_mille", "number_formats") || "‰"
      end

      # Get infinity symbol
      def infinity_symbol
        @resolver.resolve("number_formats.symbols.infinity", "number_formats") || "∞"
      end

      # Get NaN symbol
      def nan_symbol
        @resolver.resolve("number_formats.symbols.nan", "number_formats") || "NaN"
      end

      # Get decimal format pattern
      def decimal_pattern(style="standard")
        @resolver.resolve("number_formats.decimal_formats.#{style}", "number_formats") || default_decimal_pattern
      end

      # Get percent format pattern
      def percent_pattern(style="standard")
        @resolver.resolve("number_formats.percent_formats.#{style}", "number_formats") || default_percent_pattern
      end

      # Get currency format pattern
      def currency_pattern(style="standard")
        @resolver.resolve(
          "number_formats.currency_formats.#{style}",
          "number_formats"
        ) || default_currency_pattern(style)
      end

      # Get scientific format pattern
      def scientific_pattern(style="standard")
        @resolver.resolve("number_formats.scientific_formats.#{style}", "number_formats") || default_scientific_pattern
      end

      # Get currency symbol for a given currency code
      def currency_symbol(currency_code)
        @resolver.resolve("number_formats.currencies.#{currency_code}.symbol", "number_formats") || currency_code
      end

      # Get currency display name for a given currency code and plural form
      def currency_display_name(currency_code, count="other")
        @resolver.resolve("number_formats.currencies.#{currency_code}.display_names.#{count}", "number_formats") ||
          @resolver.resolve("number_formats.currencies.#{currency_code}.display_names.other", "number_formats") ||
          currency_code
      end

      # Get decimal digits for a currency (defaults to 2 if not found)
      def currency_digits(currency_code)
        @resolver.resolve("currency_fractions.#{currency_code}.digits", "number_formats") || 2
      end

      # Get cash digits for a currency (falls back to regular digits)
      def currency_cash_digits(currency_code)
        @resolver.resolve(
          "currency_fractions.#{currency_code}.cash_digits",
          "number_formats"
        ) || currency_digits(currency_code)
      end

      # Get all available currency codes
      def currency_codes
        currencies = @resolver.resolve("number_formats.currencies", "number_formats")
        currencies&.keys || []
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
