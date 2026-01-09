# frozen_string_literal: true

require "icu4x"

# Namespace for item localization function handlers
module ItemFunctions
  # Base class for language-specific item localization functions.
  #
  # Provides common fluent functions (ITEM, ITEM_WITH_COUNT) and template methods
  # for subclasses to override language-specific behavior.
  #
  # Note on the `locale` parameter:
  # Foxtail::Bundle passes `locale:` to all custom functions. This class uses it
  # with ICU4X::NumberFormat to provide locale-aware number formatting
  # (e.g., 1,000 for en, 1.000 for de, 1 000 for fr).
  #
  # Note on the `cap` parameter:
  # Capitalization at sentence start is technically a message-layer concern,
  # not an item-layer concern. However, Fluent does not support function nesting
  # (e.g., CAPITALIZE(ITEM_WITH_COUNT(...))), so we use the `cap` parameter as a
  # pragmatic workaround. The message layer passes `cap: "true"` as a hint
  # when the result will appear at sentence start.
  class Base
    def initialize(items_bundle)
      @items_bundle = items_bundle
    end

    # Returns the custom Fluent functions provided by this handler.
    # Subclasses may override this method to provide different functions.
    # @return [Hash{String => #call}] function name to callable mapping
    def functions
      {
        "ITEM" => method(:fluent_item),
        "ITEM_WITH_COUNT" => method(:fluent_item_with_count)
      }
    end

    # Fluent function: ITEM - Returns a localized item name with optional article.
    #
    # @param item_id [String] the item term reference (e.g., "-sword", "-potion")
    # @param count [Integer] the quantity of items (affects pluralization and article)
    # @param type [String] article type (language-dependent)
    # @param case [String] grammatical case (language-dependent)
    # @param cap [String] capitalize first letter: "true" or "false"
    # @return [String] the formatted item name with article
    # @note The trailing ** is required because Foxtail::Bundle passes additional
    #   keyword arguments (e.g., locale:) that this function does not use.
    def fluent_item(item_id, count=1, type: "indefinite", case: "nominative", cap: "false", **)
      grammatical_case = {case:}[:case]

      item = resolve_item(item_id, count, grammatical_case)
      article = resolve_article(item_id, count, type, grammatical_case)
      result = format_article_item(article, item)
      cap == "true" ? capitalize_first(result) : result
    end

    # Fluent function: ITEM_WITH_COUNT - Returns a localized item name with count.
    #
    # @param item_id [String] the item term reference (e.g., "-sword", "-potion")
    # @param count [Integer] the quantity of items
    # @param type [String] article type (language-dependent)
    # @param case [String] grammatical case (language-dependent)
    # @param cap [String] capitalize first letter: "true" or "false"
    # @param locale [ICU4X::Locale] the locale for number formatting
    # @return [String] the formatted item name with count (e.g., "3 swords", "a flask of potion")
    def fluent_item_with_count(item_id, count, locale:, type: "none", case: "nominative", cap: "false", **)
      grammatical_case = {case:}[:case]

      counter_term = resolve_counter_term(item_id)

      result = if counter_term
                 format_count_item_with_counter(counter_term, item_id, count, type, grammatical_case, locale)
               elsif count == 1 && type != "none"
                 item = resolve_item(item_id, count, grammatical_case)
                 article = resolve_article(item_id, count, type, grammatical_case)
                 format_article_item(article, item)
               else
                 "#{format_count(count, locale)} #{resolve_item(item_id, count, grammatical_case)}"
               end

      cap == "true" ? capitalize_first(result) : result
    end

    private def capitalize_first(str) = str.sub(/\A\p{Ll}/, &:upcase)

    private def format_count(count, locale) = ICU4X::NumberFormat.new(locale).format(count)

    private def format_article_counter_item(article, counter, item)
      return [counter, item].compact.join(" ") unless article

      term = @items_bundle.term("-fmt-article-counter-item")
      if term
        @items_bundle.format_pattern(term.value, article:, counter:, item:)
      else
        "#{article} #{counter} #{item}"
      end
    end

    private def format_article_item(article, item)
      return item unless article

      term = @items_bundle.term("-fmt-article-item")
      if term
        @items_bundle.format_pattern(term.value, article:, item:)
      else
        "#{article} #{item}"
      end
    end

    private def format_count_item_with_counter(counter_term, item_id, count, type, grammatical_case, locale)
      item = resolve_item(item_id, 1, grammatical_case)
      counter = @items_bundle.format_pattern(counter_term.value, count:, case: grammatical_case)

      if count == 1 && type != "none"
        counter_gender = counter_term.attributes&.dig("gender")
        article = resolve_article_for_counter(counter_term, counter_gender, count, type, grammatical_case)
        format_article_counter_item(article, counter, item)
      else
        format_count_counter_item(count, counter, item, locale)
      end
    end

    private def format_count_counter_item(count, counter, item, locale)
      term = @items_bundle.term("-fmt-count-counter-item")
      formatted_count = format_count(count, locale)
      if term
        @items_bundle.format_pattern(term.value, count: formatted_count, counter:, item:)
      else
        "#{formatted_count} #{counter} #{item}"
      end
    end

    private def resolve_article(_item_id, _count, _type, _grammatical_case) = nil

    private def resolve_article_for_counter(_counter_term, gender, count, type, grammatical_case)
      return nil unless gender

      resolve_article_for_gender(gender, count, type, grammatical_case)
    end

    private def resolve_article_for_gender(_gender, _count, _type, _grammatical_case) = nil

    private def resolve_counter_term(item_id)
      term = @items_bundle.term(item_id)
      return nil unless term&.attributes&.dig("counter")

      counter_attr = term.attributes["counter"]
      counter_str = counter_attr.is_a?(String) ? counter_attr : @items_bundle.format_pattern(counter_attr)
      return nil unless counter_str.start_with?("-")

      @items_bundle.term(counter_str)
    end

    private def resolve_item(item_id, count, grammatical_case)
      term = @items_bundle.term(item_id)
      return "{#{item_id}}" unless term

      @items_bundle.format_pattern(term.value, count:, case: grammatical_case)
    end
  end
end
