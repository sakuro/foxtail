# frozen_string_literal: true

# German-specific item localization functions
module ItemFunctions
  # German item localization handler.
  #
  # Provides article declension based on grammatical gender (masculine, feminine, neuter),
  # number (singular, plural), and case (nominative, accusative, dative, genitive).
  class De < Base
    # @return [Hash{String => #call}] ARTICLE_ITEM and COUNT_ITEM functions
    def functions
      {
        "ARTICLE_ITEM" => method(:fluent_article_item),
        "COUNT_ITEM" => method(:fluent_count_item)
      }
    end

    # L1: entry points from Base (alphabetical)
    private def resolve_article(item_id, count, type, grammatical_case)
      return nil if type == "none"
      # Indefinite only for singular
      return nil if type == "indefinite" && count != 1

      gender = resolve_gender(item_id)
      return nil unless gender

      term_name = type == "definite" ? "-def-article" : "-indef-article"
      term = @items_bundle.term(term_name)
      return nil unless term

      @items_bundle.format_pattern(
        term.value,
        gender:,
        count:,
        case: grammatical_case
      )
    end

    private def resolve_article_for_gender(gender, count, type, grammatical_case)
      return nil if type == "none"
      return nil if type == "indefinite" && count != 1

      term_name = type == "definite" ? "-def-article" : "-indef-article"
      term = @items_bundle.term(term_name)
      return nil unless term

      @items_bundle.format_pattern(
        term.value,
        gender:,
        count:,
        case: grammatical_case
      )
    end

    # L2: called by L1
    private def resolve_gender(item_id)
      term = @items_bundle.term("-#{item_id}")
      term&.attributes&.dig("gender")
    end
  end
end
