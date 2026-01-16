# frozen_string_literal: true

# Example 02: German Nouns from CSV
#
# This example demonstrates:
# - Building FTL AST nodes programmatically (without parsing)
# - Creating Terms with nested SelectExpressions for German noun declension
# - Adding attributes to terms
# - Serializing the AST to FTL format
#
# Input: CSV file with German noun declension data
# Output: FTL term definitions with $count and $case selectors
#
# Prints the generated FTL to stdout.

require "csv"
require "foxtail-tools"
require "pathname"

AST = Foxtail::Syntax::Parser::AST

# Build a case SelectExpression for a single number (singular or plural)
def build_case_select(nom, acc, dat, gen)
  selector = AST::VariableReference.new(AST::Identifier.new("case"))
  variants = [
    AST::Variant.new(
      AST::Identifier.new("nominative"),
      AST::Pattern.new([AST::TextElement.new(nom)]),
      default: true
    ),
    AST::Variant.new(
      AST::Identifier.new("accusative"),
      AST::Pattern.new([AST::TextElement.new(acc)])
    ),
    AST::Variant.new(
      AST::Identifier.new("dative"),
      AST::Pattern.new([AST::TextElement.new(dat)])
    ),
    AST::Variant.new(
      AST::Identifier.new("genitive"),
      AST::Pattern.new([AST::TextElement.new(gen)])
    )
  ]
  AST::SelectExpression.new(selector, variants)
end

# Build a count SelectExpression containing nested case selectors
def build_count_select(row)
  singular_case = build_case_select(
    row["nom_sg"], row["acc_sg"], row["dat_sg"], row["gen_sg"]
  )
  plural_case = build_case_select(
    row["nom_pl"], row["acc_pl"], row["dat_pl"], row["gen_pl"]
  )

  selector = AST::VariableReference.new(AST::Identifier.new("count"))
  variants = [
    AST::Variant.new(
      AST::Identifier.new("one"),
      AST::Pattern.new([AST::Placeable.new(singular_case)])
    ),
    AST::Variant.new(
      AST::Identifier.new("other"),
      AST::Pattern.new([AST::Placeable.new(plural_case)]),
      default: true
    )
  ]
  AST::SelectExpression.new(selector, variants)
end

# Build a Term node from a CSV row
def build_term(row)
  value = AST::Pattern.new([AST::Placeable.new(build_count_select(row))])
  gender_attr = AST::Attribute.new(
    AST::Identifier.new("gender"),
    AST::Pattern.new([AST::TextElement.new(row["gender"])])
  )
  AST::Term.new(
    AST::Identifier.new(row["id"]),
    value,
    [gender_attr]
  )
end

# Main
csv_path = Pathname.new(__dir__).join("02_german_nouns_from_csv.csv")
csv = CSV.read(csv_path, headers: true)

resource = AST::Resource.new
csv.each do |row|
  resource.body << build_term(row)
end

serializer = Foxtail::Syntax::Serializer.new
puts serializer.serialize(resource)
