# frozen_string_literal: true

# Namespace for item localization function handlers
module ItemFunctions
  # Base class for language-specific item localization functions.
  #
  # Provides common fluent functions (ARTICLE_ITEM, COUNT_ITEM) and template methods
  # for subclasses to override language-specific behavior.
  #
  # Note on the `cap` parameter:
  # Capitalization at sentence start is technically a message-layer concern,
  # not an item-layer concern. However, Fluent does not support function nesting
  # (e.g., CAPITALIZE(COUNT_ITEM(...))), so we use the `cap` parameter as a
  # pragmatic workaround. The message layer passes `cap: "true"` as a hint
  # when the result will appear at sentence start.
  class Base
    def initialize(items_bundle)
      @items_bundle = items_bundle
    end

    # Returns the custom Fluent functions provided by this handler.
    # Subclasses must override this method.
    # @return [Hash{String => #call}] function name to callable mapping
    def functions
      raise NotImplementedError, "Subclasses must implement #functions"
    end

    # Fluent function: ARTICLE_ITEM(item_id, count = 1, type: "indefinite", case: "nominative", cap: "false")
    def fluent_article_item(item_id, count=1, **options)
      type = options.fetch(:type, "indefinite")
      grammatical_case = options.fetch(:case, "nominative")
      cap = options.fetch(:cap, "false")

      item = resolve_item(item_id, count, grammatical_case)
      article = resolve_article(item_id, count, type, grammatical_case)
      result = format_article_item(article, item)
      cap == "true" ? capitalize_first(result) : result
    end

    # Fluent function: COUNT_ITEM(item_id, count, type: "none", case: "nominative", cap: "false")
    def fluent_count_item(item_id, count, **options)
      type = options.fetch(:type, "none")
      grammatical_case = options.fetch(:case, "nominative")
      cap = options.fetch(:cap, "false")

      counter_term = resolve_counter_term(item_id)

      result = if counter_term
                 format_count_item_with_counter(counter_term, item_id, count, type, grammatical_case)
               elsif count == 1 && type != "none"
                 item = resolve_item(item_id, count, grammatical_case)
                 article = resolve_article(item_id, count, type, grammatical_case)
                 format_article_item(article, item)
               else
                 "#{count} #{resolve_item(item_id, count, grammatical_case)}"
               end

      cap == "true" ? capitalize_first(result) : result
    end

    private def capitalize_first(str) = str.sub(/\A\p{Ll}/, &:upcase)

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

    private def format_count_item_with_counter(counter_term, item_id, count, type, grammatical_case)
      item = resolve_item(item_id, 1, grammatical_case)
      counter = @items_bundle.format_pattern(counter_term.value, count:, case: grammatical_case)

      if count == 1 && type != "none"
        counter_gender = counter_term.attributes&.dig("gender")
        article = resolve_article_for_counter(counter_term, counter_gender, count, type, grammatical_case)
        format_article_counter_item(article, counter, item)
      else
        format_count_counter_item(count, counter, item)
      end
    end

    private def format_count_counter_item(count, counter, item)
      term = @items_bundle.term("-fmt-count-counter-item")
      if term
        @items_bundle.format_pattern(term.value, count:, counter:, item:)
      else
        "#{count} #{counter} #{item}"
      end
    end

    private def resolve_article(_item_id, _count, _type, _grammatical_case) = nil

    private def resolve_article_for_counter(_counter_term, gender, count, type, grammatical_case)
      return nil unless gender

      resolve_article_for_gender(gender, count, type, grammatical_case)
    end

    private def resolve_article_for_gender(_gender, _count, _type, _grammatical_case) = nil

    private def resolve_counter_term(item_id)
      term = @items_bundle.term("-#{item_id}")
      return nil unless term&.attributes&.dig("counter")

      counter_attr = term.attributes["counter"]
      counter_str = counter_attr.is_a?(String) ? counter_attr : @items_bundle.format_pattern(counter_attr)
      return nil unless counter_str.start_with?("-")

      @items_bundle.term(counter_str)
    end

    private def resolve_item(item_id, count, grammatical_case)
      term = @items_bundle.term("-#{item_id}")
      return "{#{item_id}}" unless term

      @items_bundle.format_pattern(term.value, count:, case: grammatical_case)
    end
  end
end
