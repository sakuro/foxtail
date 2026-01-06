# frozen_string_literal: true

# Japanese-specific item localization functions
module ItemFunctions
  # Japanese item localization handler.
  #
  # Provides counter word (助数詞) support for items. Each item can have a
  # counter defined via .counter attribute (e.g., 振 for swords, 瓶 for bottles).
  class Ja < Base
    # @return [Hash{String => #call}] ITEM and COUNT functions
    def functions
      {
        "COUNT" => method(:fluent_count),
        "ITEM" => method(:fluent_item)
      }
    end

    # Fluent function: ITEM(item_id)
    def fluent_item(item_id, **)
      resolve_item(item_id, 1, "nominative")
    end

    # Fluent function: COUNT(item_id, count)
    def fluent_count(item_id, count, **)
      format_count(item_id, count)
    end

    # "3組", "1瓶"
    def format_count(item_id, count)
      counter = resolve_counter(item_id, count)
      "#{count}#{counter || "個"}"
    end

    private def resolve_counter(item_id, count)
      counter_info = resolve_counter_attr(item_id)
      return nil unless counter_info

      counter_value, is_term = counter_info
      if is_term
        counter_term = @items_bundle.term(counter_value)
        return nil unless counter_term

        @items_bundle.format_pattern(counter_term.value, count:)
      else
        counter_value
      end
    end

    private def resolve_counter_attr(item_id)
      term = @items_bundle.term("-#{item_id}")
      return nil unless term&.attributes&.dig("counter")

      counter_attr = term.attributes["counter"]
      counter_str = counter_attr.is_a?(String) ? counter_attr : @items_bundle.format_pattern(counter_attr)
      [counter_str, counter_str.start_with?("-")]
    end
  end
end
