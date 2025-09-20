# frozen_string_literal: true

require "locale"

module Foxtail
  module CLDR
    module Repository
      # CLDR number formatting data loader and processor
      #
      # Provides locale-specific number formatting information including
      # decimal symbols, grouping, and number formatting patterns with
      # support for decimal, percent, currency, and scientific notation.
      #
      # @example
      #   formats = NumberFormats.new("en")
      #   formats.decimal_symbol      # => "."
      #   formats.group_symbol        # => ","
      #   formats.decimal_pattern     # => "#,##0.###"
      #   formats.percent_pattern     # => "#,##0%"
      #
      # @see https://unicode.org/reports/tr35/tr35-numbers.html
      class NumberFormats < Base
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
          @resolver.resolve("number_formats.decimal_formats.#{style}", "number_formats")
        end

        # Get percent format pattern
        def percent_pattern(style="standard")
          @resolver.resolve("number_formats.percent_formats.#{style}", "number_formats")
        end

        # Get currency format pattern
        def currency_pattern(style="standard")
          @resolver.resolve("number_formats.currency_formats.#{style}", "number_formats")
        end

        # Get scientific format pattern
        def scientific_pattern(style="standard")
          @resolver.resolve("number_formats.scientific_formats.#{style}", "number_formats")
        end

        # Get compact format pattern for given magnitude and display style
        def compact_pattern(magnitude, compact_display="short", count="other")
          pattern = @resolver.resolve("number_formats.compact_formats.#{compact_display}.#{magnitude}.#{count}", "number_formats")

          # Fallback to "one" if "other" is not found (common in English CLDR data)
          if pattern.nil? && count == "other"
            pattern = @resolver.resolve("number_formats.compact_formats.#{compact_display}.#{magnitude}.one", "number_formats")
          end

          pattern
        end

        # Get all compact format patterns for a display style
        def compact_patterns(compact_display="short")
          @resolver.resolve("number_formats.compact_formats.#{compact_display}", "number_formats") || {}
        end

        # Get default significant digits settings for compact notation
        # Based on Node.js Intl.NumberFormat defaults for decimal compact notation
        def compact_decimal_significant_digits
          {maximum: 2, minimum: 1}
        end

        # Get decimal digits for a currency (defaults to 2 if not found)
        def currency_digits(currency_code)
          @resolver.resolve("currency_fractions.#{currency_code}.digits", "number_formats") || 2
        end
      end
    end
  end
end
