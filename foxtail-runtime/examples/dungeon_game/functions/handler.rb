# frozen_string_literal: true

require "icu4x"

# Namespace for item localization function handlers
module ItemFunctions
  # Base handler class for language-specific item localization.
  #
  # Provides formatting methods for ITEM and ITEM_WITH_COUNT functions.
  # Subclasses override template methods for language-specific behavior.
  #
  # Note on the `cap` parameter:
  # Capitalization at sentence start is technically a message-layer concern,
  # not an item-layer concern. However, Fluent does not support function nesting
  # (e.g., CAPITALIZE(ITEM_WITH_COUNT(...))), so we use the `cap` parameter as a
  # pragmatic workaround. The message layer passes `cap: "true"` as a hint
  # when the result will appear at sentence start.
  class Handler
    def initialize(bundle) = @bundle = bundle

    # Format an item with optional article.
    # Called by Item#format with the bundle context.
    #
    # @param item_id [String] the item term reference
    # @param bundle [Foxtail::Bundle] the bundle providing locale context
    # @param count [Integer] the quantity of items
    # @param type [String] article type (language-dependent)
    # @param case [String] grammatical case (language-dependent)
    # @param cap [String] capitalize first letter: "true" or "false"
    # @return [String] the formatted item name with article
    def format_item(item_id, count: 1, type: "indefinite", case: "nominative", cap: "false", **)
      # Unwrap Function::Value arguments
      item_id = unwrap(item_id)
      count = unwrap(count)
      type = unwrap(type)
      cap = unwrap(cap)
      grammatical_case = unwrap({case:}[:case])

      item = resolve_item(item_id, count, grammatical_case)
      article = resolve_article(item_id, count, type, grammatical_case)
      result = format_article_item(article, item)
      cap == "true" ? capitalize_first(result) : result
    end

    # Format an item with count.
    # Called by ItemWithCount#format with the bundle context.
    #
    # @param item_id [String] the item term reference
    # @param count [Integer] the quantity of items
    # @param bundle [Foxtail::Bundle] the bundle providing locale context
    # @param type [String] article type (language-dependent)
    # @param case [String] grammatical case (language-dependent)
    # @param cap [String] capitalize first letter: "true" or "false"
    # @return [String] the formatted item name with count
    def format_item_with_count(item_id, count, bundle:, type: "none", case: "nominative", cap: "false", **)
      # Unwrap Function::Value arguments
      item_id = unwrap(item_id)
      count = unwrap(count)
      type = unwrap(type)
      cap = unwrap(cap)
      grammatical_case = unwrap({case:}[:case])

      counter_term = resolve_counter_term(item_id)

      result = if counter_term
                 format_count_item_with_counter(counter_term, item_id, count, type, grammatical_case, bundle.locale)
               elsif count == 1 && type != "none"
                 item = resolve_item(item_id, count, grammatical_case)
                 article = resolve_article(item_id, count, type, grammatical_case)
                 format_article_item(article, item)
               else
                 "#{format_count(count, bundle.locale)} #{resolve_item(item_id, count, grammatical_case)}"
               end

      cap == "true" ? capitalize_first(result) : result
    end

    private def unwrap(value) = value.is_a?(Foxtail::Function::Value) ? value.value : value

    private def capitalize_first(str) = str.sub(/\A\p{Ll}/, &:upcase)

    private def format_count(count, locale) = Foxtail::ICU4XCache.instance.number_formatter(locale).format(count)

    private def format_article_counter_item(article, counter, item)
      return [counter, item].compact.join(" ") unless article

      term = @bundle.term("-fmt-article-counter-item")
      if term
        @bundle.format_pattern(term.value, article:, counter:, item:)
      else
        "#{article} #{counter} #{item}"
      end
    end

    private def format_article_item(article, item)
      return item unless article

      term = @bundle.term("-fmt-article-item")
      if term
        @bundle.format_pattern(term.value, article:, item:)
      else
        "#{article} #{item}"
      end
    end

    private def format_count_item_with_counter(counter_term, item_id, count, type, grammatical_case, locale)
      item = resolve_item(item_id, 1, grammatical_case)
      counter = @bundle.format_pattern(counter_term.value, count:, case: grammatical_case)

      if count == 1 && type != "none"
        counter_gender = counter_term.attributes&.dig("gender")
        article = resolve_article_for_counter(counter_term, counter_gender, count, type, grammatical_case)
        format_article_counter_item(article, counter, item)
      else
        format_count_counter_item(count, counter, item, locale)
      end
    end

    private def format_count_counter_item(count, counter, item, locale)
      term = @bundle.term("-fmt-count-counter-item")
      formatted_count = format_count(count, locale)
      if term
        @bundle.format_pattern(term.value, count: formatted_count, counter:, item:)
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
      term = @bundle.term(item_id)
      return nil unless term&.attributes&.dig("counter")

      counter_attr = term.attributes["counter"]
      counter_str = counter_attr.is_a?(String) ? counter_attr : @bundle.format_pattern(counter_attr)
      return nil unless counter_str.start_with?("-")

      @bundle.term(counter_str)
    end

    private def resolve_item(item_id, count, grammatical_case)
      term = @bundle.term(item_id)
      return "{#{item_id}}" unless term

      @bundle.format_pattern(term.value, count:, case: grammatical_case)
    end
  end
end
