# frozen_string_literal: true

# German-specific item localization functions
module ItemFunctions
  # German item localization handler.
  #
  # Provides article declension based on grammatical gender (masculine, feminine, neuter),
  # number (singular, plural), and case (nominative, accusative, dative, genitive).
  class De < Base
    private def resolve_article(item_id, count, type, grammatical_case)
      return nil if type == "none"
      # Indefinite only for singular
      return nil if type == "indefinite" && count != 1

      gender = resolve_gender(item_id)
      return nil unless gender

      term_name = type == "definite" ? "-def-article" : "-indef-article"
      term = @bundle.term(term_name)
      return nil unless term

      @bundle.format_pattern(
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
      term = @bundle.term(term_name)
      return nil unless term

      @bundle.format_pattern(
        term.value,
        gender:,
        count:,
        case: grammatical_case
      )
    end

    private def resolve_gender(item_id)
      term = @bundle.term(item_id)
      term&.attributes&.dig("gender")
    end
  end
end
