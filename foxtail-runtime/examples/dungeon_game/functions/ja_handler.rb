# frozen_string_literal: true

require_relative "handler"

# Japanese-specific item localization functions
module ItemFunctions
  # Japanese item localization handler.
  #
  # Provides counter word (助数詞) support for items. Each item can have a
  # counter defined via .counter attribute (e.g., 振 for swords, 瓶 for bottles).
  class JaHandler < Handler
    # Format an item name.
    #
    # Japanese items do not require articles or grammatical case handling,
    # so this is a simplified version of the base class method.
    #
    # @param item_id [String] the item term reference (e.g., "-sword", "-potion")
    # @param bundle [Foxtail::Bundle] the bundle providing locale context
    # @return [String] the localized item name
    def format_item(item_id, **)
      item_id = unwrap(item_id)
      resolve_item(item_id, 1, "nominative")
    end

    # Format an item with count using counter words.
    #
    # Formats as: "<count><counter>の<item>" (e.g., "5瓶の回復薬")
    #
    # @param item_id [String] the item term reference (e.g., "-sword", "-healing-potion")
    # @param count [Integer] the quantity of items
    # @param bundle [Foxtail::Bundle] the bundle providing locale context
    # @return [String] the formatted item with count and counter
    def format_item_with_count(item_id, count, bundle:, **)
      item_id = unwrap(item_id)
      count = unwrap(count)
      item = resolve_item(item_id, count, "nominative")
      counter = resolve_counter(item_id) || "個"
      "#{format_count(count, bundle.locale)}#{counter}の#{item}"
    end

    private def resolve_counter(item_id)
      term = @bundle.term(item_id)
      return nil unless term&.attributes&.dig("counter")

      counter_attr = term.attributes["counter"]
      counter_attr.is_a?(String) ? counter_attr : @bundle.format_pattern(counter_attr)
    end
  end
end
