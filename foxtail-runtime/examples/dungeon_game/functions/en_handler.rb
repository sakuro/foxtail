# frozen_string_literal: true

require_relative "handler"

# English-specific item localization functions
module ItemFunctions
  # English item localization handler.
  #
  # Provides indefinite article selection (a/an) based on first letter,
  # with support for explicit overrides via .indef attribute.
  class EnHandler < Handler
    private def resolve_article(item_id, count, type, _grammatical_case=nil)
      return nil if type == "none"
      # Indefinite only for singular
      return nil if type == "indefinite" && count != 1

      if type == "definite"
        resolve_definite_article
      else
        resolve_indefinite_article(item_id, count)
      end
    end

    private def resolve_article_for_counter(counter_term, _gender, count, type, _grammatical_case)
      if type == "definite"
        resolve_definite_article
      else
        resolve_indefinite_article_for_counter(counter_term, count)
      end
    end

    private def resolve_definite_article
      term = @bundle.term("-def-article")
      return "the" unless term

      @bundle.format_pattern(term.value)
    end

    private def resolve_indefinite_article(item_id, count)
      # Check explicit .indef attribute first
      item_term = @bundle.term(item_id)
      return item_term.attributes["indef"] if item_term&.attributes&.key?("indef")

      # Use FTL term with first_letter selector
      term = @bundle.term("-indef-article")
      return "a" unless term

      item = resolve_item(item_id, count, nil)
      first_letter = extract_first_letter(item)
      @bundle.format_pattern(term.value, first_letter:)
    end

    private def resolve_indefinite_article_for_counter(counter_term, count)
      # Check explicit .indef attribute first
      return counter_term.attributes["indef"] if counter_term.attributes&.key?("indef")

      # Use FTL term with first_letter selector
      term = @bundle.term("-indef-article")
      return "a" unless term

      counter = @bundle.format_pattern(counter_term.value, count:)
      first_letter = extract_first_letter(counter)
      @bundle.format_pattern(term.value, first_letter:)
    end

    # Extract first letter, handling accented characters via NFD normalization
    # e.g., "élixir" → NFD → "e" + combining accent → first char "e"
    private def extract_first_letter(str) = str.unicode_normalize(:nfd)[0]&.downcase
  end
end
