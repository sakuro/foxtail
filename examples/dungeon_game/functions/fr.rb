# frozen_string_literal: true

# French-specific item localization functions
module ItemFunctions
  # French item localization handler.
  #
  # Provides article selection with elision handling (le/la → l' before vowels),
  # with support for h aspiré exceptions via .elision attribute.
  class Fr < Base
    private def format_article_counter_item(article, counter, item, counter_elision: false)
      unless article
        term = @items_bundle.term("-fmt-counter-item")
        return @items_bundle.format_pattern(term.value, counter:, item:, elision: counter_elision.to_s)
      end

      article_elision = article.end_with?("'")
      term = @items_bundle.term("-fmt-article-counter-item")
      @items_bundle.format_pattern(
        term.value,
        article:,
        counter:,
        item:,
        article_elision: article_elision.to_s,
        counter_elision: counter_elision.to_s
      )
    end

    private def format_article_item(article, item)
      return item unless article

      elision = article.end_with?("'")
      term = @items_bundle.term("-fmt-article-item")
      @items_bundle.format_pattern(term.value, article:, item:, elision: elision.to_s)
    end

    private def format_count_item_with_counter(counter_term, item_id, count, type, grammatical_case)
      item = resolve_item(item_id, 1, grammatical_case)
      item_elision = should_elide_for_item?(item_id)
      counter = @items_bundle.format_pattern(counter_term.value, count:, elision: item_elision.to_s)

      if count == 1 && type != "none"
        counter_gender = counter_term.attributes&.dig("gender") || "feminine"
        article = resolve_article_for_counter(counter_term, counter_gender, count, type, grammatical_case)
        format_article_counter_item(article, counter, item, counter_elision: item_elision)
      else
        format_count_counter_item(count, counter, item, item_elision)
      end
    end

    private def format_count_counter_item(count, counter, item, elision)
      term = @items_bundle.term("-fmt-count-counter-item")
      @items_bundle.format_pattern(term.value, count:, counter:, item:, elision: elision.to_s)
    end

    private def resolve_article(item_id, count, type, _grammatical_case=nil)
      return nil if type == "none"

      term = @items_bundle.term("-#{item_id}")
      gender = term&.attributes&.dig("gender") || "masculine"
      elision = should_elide?(term, item_id, count)

      if type == "definite"
        resolve_definite_article(gender, count, elision)
      else
        resolve_indefinite_article(gender, count)
      end
    end

    private def resolve_article_for_counter(counter_term, gender, count, type, _grammatical_case)
      elision = should_elide_counter?(counter_term, count)

      if type == "definite"
        resolve_definite_article(gender, count, elision)
      else
        resolve_indefinite_article(gender, count)
      end
    end

    private def resolve_definite_article(gender, count, elision)
      term = @items_bundle.term("-def-article")
      return nil unless term

      @items_bundle.format_pattern(
        term.value,
        gender:,
        count:,
        elision: elision.to_s
      )
    end

    private def resolve_indefinite_article(gender, count)
      term = @items_bundle.term("-indef-article")
      return nil unless term

      @items_bundle.format_pattern(
        term.value,
        gender:,
        count:
      )
    end

    private def should_elide?(term, item_id, count)
      # Check explicit .elision attribute first
      if term&.attributes&.key?("elision")
        return term.attributes["elision"] != "false"
      end

      # Default: elide before vowels
      item = resolve_item(item_id, count, "nominative")
      starts_with_vowel?(item)
    end

    private def should_elide_for_item?(item_id)
      term = @items_bundle.term("-#{item_id}")

      # Check explicit .elision attribute first
      if term&.attributes&.key?("elision")
        return term.attributes["elision"] != "false"
      end

      # Default: elide before vowels
      item = resolve_item(item_id, 1, "nominative")
      starts_with_vowel?(item)
    end

    private def should_elide_counter?(counter_term, count)
      if counter_term.attributes&.key?("elision")
        return counter_term.attributes["elision"] != "false"
      end

      counter = @items_bundle.format_pattern(counter_term.value, count:)
      starts_with_vowel?(counter)
    end

    # Check if string starts with a vowel, using NFD normalization
    # e.g., "épée" → NFD → "e" + combining accent → first char "e" (vowel)
    private def starts_with_vowel?(str)
      first_letter = str.unicode_normalize(:nfd)[0]&.downcase || ""
      first_letter.match?(/[aeiou]/)
    end
  end
end
