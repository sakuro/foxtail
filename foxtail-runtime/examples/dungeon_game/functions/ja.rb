# frozen_string_literal: true

# Japanese-specific item localization functions
module ItemFunctions
  # Japanese item localization handler.
  #
  # Provides counter word (助数詞) support for items. Each item can have a
  # counter defined via .counter attribute (e.g., 振 for swords, 瓶 for bottles).
  class Ja < Base
    # @return [Hash{String => #call}] ITEM and ITEM_WITH_COUNT functions
    def functions
      {
        "ITEM" => method(:fluent_item),
        "ITEM_WITH_COUNT" => method(:fluent_item_with_count)
      }
    end

    # Fluent function: ITEM - Returns a localized item name.
    #
    # Japanese items do not require articles or grammatical case handling,
    # so this is a simplified version of the base class method.
    #
    # @param item_id [String] the item term reference (e.g., "-sword", "-potion")
    # @return [String] the localized item name
    # @note The trailing ** is required because Foxtail::Bundle passes additional
    #   keyword arguments (e.g., locale:) that this function does not use.
    def fluent_item(item_id, **)
      resolve_item(item_id, 1, "nominative")
    end

    # Fluent function: ITEM_WITH_COUNT - Returns count + counter + item name.
    #
    # Formats as: "<count><counter>の<item>" (e.g., "5瓶の回復薬")
    #
    # @param item_id [String] the item term reference (e.g., "-sword", "-healing-potion")
    # @param count [Integer] the quantity of items
    # @param locale [ICU4X::Locale] the locale for number formatting
    # @return [String] the formatted item with count and counter
    def fluent_item_with_count(item_id, count, locale:, **)
      item = resolve_item(item_id, count, "nominative")
      counter = resolve_counter(item_id) || "個"
      "#{format_count(count, locale)}#{counter}の#{item}"
    end

    private def resolve_counter(item_id)
      term = @items_bundle.term(item_id)
      return nil unless term&.attributes&.dig("counter")

      counter_attr = term.attributes["counter"]
      counter_attr.is_a?(String) ? counter_attr : @items_bundle.format_pattern(counter_attr)
    end
  end
end
