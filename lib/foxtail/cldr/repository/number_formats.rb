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
        # Get decimal symbol for a specific numbering system
        def decimal_symbol(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.decimal", "number_formats") || "."
        end

        # Get grouping symbol for a specific numbering system
        def group_symbol(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.group", "number_formats") || ","
        end

        # Get minus sign for a specific numbering system
        def minus_sign(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.minus_sign", "number_formats") || "-"
        end

        # Get plus sign for a specific numbering system
        def plus_sign(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.plus_sign", "number_formats") || "+"
        end

        # Get percent sign for a specific numbering system
        def percent_sign(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.percent_sign", "number_formats") || "%"
        end

        # Get per mille sign
        def per_mille_sign(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.per_mille", "number_formats") || "‰"
        end

        # Get infinity symbol for a specific numbering system
        def infinity_symbol(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.infinity", "number_formats") || "∞"
        end

        # Get NaN symbol for a specific numbering system
        def nan_symbol(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.nan", "number_formats") || "NaN"
        end

        # Get exponential symbol for a specific numbering system
        def exponential_symbol(numbering_system="latn")
          @resolver.resolve("number_formats.#{numbering_system}.symbols.exponential", "number_formats") || "E"
        end

        # Get decimal format pattern for a specific numbering system
        def decimal_pattern(style="standard", numbering_system="latn")
          pattern = @resolver.resolve("number_formats.#{numbering_system}.decimal_formats.#{style}", "number_formats")
          # Fallback to latn numbering system if pattern not found for the specified numbering system
          if pattern.nil? && numbering_system != "latn"
            pattern = @resolver.resolve("number_formats.latn.decimal_formats.#{style}", "number_formats")
          end
          pattern
        end

        # Get percent format pattern for a specific numbering system
        def percent_pattern(style="standard", numbering_system="latn")
          pattern = @resolver.resolve("number_formats.#{numbering_system}.percent_formats.#{style}", "number_formats")
          # Fallback to latn numbering system if pattern not found for the specified numbering system
          if pattern.nil? && numbering_system != "latn"
            pattern = @resolver.resolve("number_formats.latn.percent_formats.#{style}", "number_formats")
          end
          pattern
        end

        # Get currency format pattern for a specific numbering system
        def currency_pattern(style="standard", numbering_system="latn")
          pattern = @resolver.resolve("number_formats.#{numbering_system}.currency_formats.#{style}", "number_formats")
          # Fallback to latn numbering system if pattern not found for the specified numbering system
          if pattern.nil? && numbering_system != "latn"
            pattern = @resolver.resolve("number_formats.latn.currency_formats.#{style}", "number_formats")
          end
          pattern
        end

        # Get scientific format pattern for a specific numbering system
        def scientific_pattern(style="standard", numbering_system="latn")
          pattern = @resolver.resolve("number_formats.#{numbering_system}.scientific_formats.#{style}", "number_formats")
          # Fallback to latn numbering system if pattern not found for the specified numbering system
          if pattern.nil? && numbering_system != "latn"
            pattern = @resolver.resolve("number_formats.latn.scientific_formats.#{style}", "number_formats")
          end
          pattern
        end

        # Get compact format pattern for given magnitude and display style
        def compact_pattern(magnitude, compact_display="short", count="other", numbering_system="latn")
          pattern = @resolver.resolve("number_formats.#{numbering_system}.compact_formats.#{compact_display}.#{magnitude}.#{count}", "number_formats")

          # Fallback to "one" if "other" is not found (common in English CLDR data)
          if pattern.nil? && count == "other"
            pattern = @resolver.resolve("number_formats.#{numbering_system}.compact_formats.#{compact_display}.#{magnitude}.one", "number_formats")
          end

          # Fallback to latn numbering system if pattern not found for the specified numbering system
          if pattern.nil? && numbering_system != "latn"
            pattern = @resolver.resolve("number_formats.latn.compact_formats.#{compact_display}.#{magnitude}.#{count}", "number_formats")
            # Also try "one" fallback for latn if "other" not found
            if pattern.nil? && count == "other"
              pattern = @resolver.resolve("number_formats.latn.compact_formats.#{compact_display}.#{magnitude}.one", "number_formats")
            end
          end

          pattern
        end

        # Get all compact format patterns for a display style
        def compact_patterns(compact_display="short", numbering_system="latn")
          patterns = @resolver.resolve("number_formats.#{numbering_system}.compact_formats.#{compact_display}", "number_formats")
          # Fallback to latn numbering system if patterns not found for the specified numbering system
          if patterns.nil? && numbering_system != "latn"
            patterns = @resolver.resolve("number_formats.latn.compact_formats.#{compact_display}", "number_formats")
          end
          patterns || {}
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

        # Get numbering system settings for this locale
        # @return [Hash] Numbering system settings (default, native, traditional, etc.)
        def numbering_system_settings
          @resolver.resolve("numbering_system_settings", "number_formats") || {}
        end
      end
    end
  end
end
