# frozen_string_literal: true

require "locale"

module Foxtail
  module CLDR
    module Repository
      # CLDR currency data loader and processor
      # Provides locale-specific currency information
      #
      # Based on Unicode CLDR specifications:
      # - Currency display names, symbols, and formatting
      # - Supports localized currency names for different plural forms
      #
      # Example usage:
      #   locale = Locale::Tag.parse("ja")
      #   currencies = Currencies.new(locale)
      #   currencies.currency_name("USD")           # => "米ドル"
      #   currencies.currency_symbol("USD")         # => "$"
      #   currencies.currency_name("JPY", :one)    # => "日本円"
      class Currencies < Base
        # Get localized currency display name
        #
        # @param code [String] ISO 4217 currency code (e.g., "USD", "JPY")
        # @param count [Symbol] Plural form (:one, :other, etc.)
        # @return [String] Localized currency name, or currency code if not found
        def currency_name(code, count=:other)
          name = @resolver.resolve("currencies.#{code}.display_names.#{count}", "currencies")
          name || code
        end

        # Get currency symbol
        #
        # @param code [String] ISO 4217 currency code
        # @return [String] Currency symbol, or currency code if not found
        def currency_symbol(code)
          symbol = @resolver.resolve("currencies.#{code}.symbol", "currencies")
          symbol || code
        end

        # Get all available currency codes for this locale
        #
        # @return [Array<String>] List of currency codes
        def available_currencies
          currencies_data = @resolver.resolve("currencies", "currencies")
          currencies_data&.keys || []
        end

        # Check if currency data exists for the given code
        #
        # @param code [String] Currency code to check
        # @return [Boolean] True if currency data exists
        def currency_exists?(code)
          !@resolver.resolve("currencies.#{code}", "currencies").nil?
        end
      end
    end
  end
end
